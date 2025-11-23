//
//  ShortVideoCacheService.swift
//  FlatBread
//
//  Created by 김민성 on 11/23/25.
//

import Foundation

final class ShortVideoCacheService {
    static let shared = ShortVideoCacheService()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    init() {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ShortVideoCache")
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func getFileURL(for id: String) -> URL {
        return cacheDirectory.appendingPathComponent("\(id).mp4")
    }
    
    func getCachedSize(for id: String) -> Int64 {
        let url = getFileURL(for: id)
        guard fileManager.fileExists(atPath: url.path) else { return 0 }
        
        if let attributes = try? fileManager.attributesOfItem(atPath: url.path),
           let size = attributes[.size] as? Int64 {
            return size
        }
        return 0
    }
    
    func checkCacheExist(for id: String) -> Bool {
        return fileManager.fileExists(atPath: getFileURL(for: id).path)
    }
    
    func removeCacheFile(for id: String) {
        let url = getFileURL(for: id)
        if fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(at: url)
                print("🗑️ [CacheService] 파일 삭제 완료: \(id)")
            } catch {
                print("❌ [CacheService] 파일 삭제 실패: \(error)")
            }
        }
    }
    
    // 지금 사용되지는 않음. (설정 화면 등에서 사용)
    func clearAllCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}
