//
//  ShortVideoDiskCacheService.swift
//  FlatBread
//
//  Created by 김민성 on 11/23/25.
//

import Foundation

final class ShortVideoDiskCacheService: ShortVideoCacheService {
    static let shared = ShortVideoDiskCacheService()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    init() {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ShortVideoCache")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    private func getFileURL(for id: String) -> URL {
        return cacheDirectory.appendingPathComponent("\(id).mp4")
    }
    
    func saveCache(for id: String, cache: ShortVideoPreloadCache) {
        let fileURL = getFileURL(for: id)
        
        do {
            try cache.data.write(to: fileURL)
            UserDefaults.standard.set(cache.totalLength, forKey: "\(id)_totalLength")
            UserDefaults.standard.set(cache.contentType, forKey: "\(id)_contentType")
        } catch {
            print("❌ [DiskCache] 저장 실패: \(error)")
        }
    }
    
    func getCache(for id: String) -> ShortVideoPreloadCache? {
        let fileURL = getFileURL(for: id)
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let totalLength = Int64(UserDefaults.standard.integer(forKey: "\(id)_totalLength"))
        let contentType = UserDefaults.standard.string(forKey: "\(id)_contentType") ?? "public.mpeg-4"
        
        return ShortVideoPreloadCache(
            videoID: id,
            totalLength: totalLength,
            contentType: contentType,
            data: data
        )
    }
    
    func removeCache(for id: String) {
        let fileURL = getFileURL(for: id)
        guard fileManager.fileExists(atPath: fileURL.path()) else {
            return
        }
        try? fileManager.removeItem(at: fileURL)
        UserDefaults.standard.removeObject(forKey: "\(id)_totalLength")
        UserDefaults.standard.removeObject(forKey: "\(id)_contentType")
        print("\(id) 디스크에서 캐시 삭제됨")
    }
    
    func clearAll() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func isCached(for id: String) -> Bool {
        return fileManager.fileExists(atPath: getFileURL(for: id).path)
    }
}
