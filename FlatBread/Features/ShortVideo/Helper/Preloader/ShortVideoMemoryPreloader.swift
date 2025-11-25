//
//  ShortVideoMemoryPreloader.swift
//  FlatBread
//
//  Created by 김민성 on 11/24/25.
//

import Foundation

final class ShortVideoMemoryPreloader: ShortVideoPreloader {
    static let shared = ShortVideoMemoryPreloader()
    
    private let cacheService: ShortVideoCacheService = ShortVideoMemoryCacheService.shared
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    
    private var activeTasks: [String: Task<Void, Never>] = [:]
    private let preloadLimit: Int64 = 2 * 1024 * 1024
    
    func startPreload(video: ShortVideo) {
        let id = video.id
        
        if activeTasks[id] != nil { return }
        if cacheService.isCached(for: id) { return }
        
        guard let filePath = video.files.first else { return }
        
        let task = Task {
            let router = VideoDownloadRouter.streamVideo(
                filePath: filePath,
                lowerRange: 0,
                upperRange: preloadLimit
            )
            
            do {
                let (response, data) = try await networkService.downloadVideo(router)
                
                guard let httpResponse = response, let preloadedData = data else { return }
                
                // 메타데이터 파싱
                let contentType = httpResponse.mimeType ?? "public.mpeg-4"
                var totalLength: Int64 = httpResponse.expectedContentLength
                
                if let rangeHeader = httpResponse.allHeaderFields["Content-Range"] as? String ??
                                     httpResponse.allHeaderFields["content-range"] as? String {
                    if let totalStr = rangeHeader.components(separatedBy: "/").last?.trimmingCharacters(in: .whitespaces),
                       let length = Int64(totalStr) {
                        totalLength = length
                    }
                }
                
                if totalLength > 0 {
                    let cache = ShortVideoPreloadCache(
                        videoID: id,
                        totalLength: totalLength,
                        contentType: contentType,
                        data: preloadedData
                    )
                    
                    // 캐시 저장
                    cacheService.saveCache(for: id, cache: cache)
                    print("💾 [Memory] 프리로딩 저장 완료: \(id)")
                }
                
            } catch {
                if !(error is CancellationError) {
                    print("❌ [Memory] \(video.files.first!) 다운로드 실패: \(error)")
                }
            }
            self.activeTasks[id] = nil
        }
        activeTasks[id] = task
    }
    
    func cancelPreload(videoID: String) {
        activeTasks[videoID]?.cancel()
        activeTasks[videoID] = nil
    }
    
    func cancelAndRemoveCache(videoID: String) {
        cancelPreload(videoID: videoID)
        cacheService.removeCache(for: videoID)
    }
    
    func getPreloadData(videoID: String) -> ShortVideoPreloadCache? {
        return cacheService.getCache(for: videoID)
    }
    
    func getCachedSize(videoID: String) -> Int64 {
        if let cache = cacheService.getCache(for: videoID) {
            return Int64(cache.data.count)
        }
        return 0
    }
}
