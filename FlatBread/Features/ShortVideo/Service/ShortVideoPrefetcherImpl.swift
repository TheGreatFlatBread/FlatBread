//
//  ShortVideoPrefetcherImpl.swift
//  FlatBread
//
//  Created by 김민성 on 11/24/25.
//
//  Refactored by Gemini on 12/3/25.
//

import Foundation

final class ShortVideoPrefetcherImpl: ShortVideoPrefetcher {
    
    private let cacheService: any ShortVideoCacheService
    private let networkService: any AsyncNetworkService
    
    private var activeTasks: [String: Task<Void, Never>] = [:]
    private let prefetchLimit: Int64 = 2 * 1024 * 1024 // 2MB
    
    init(cacheService: ShortVideoCacheService, networkService: AsyncNetworkService) {
        self.cacheService = cacheService
        self.networkService = networkService
    }
    
    func startPrefetch(video: ShortVideo) {
        let id = video.id
        
        if activeTasks[id] != nil { return }
        if cacheService.isCached(for: id) { return }
        
        guard let filePath = video.files.first else { return }
        
        let task = Task {
            let router = VideoDownloadRouter.streamVideo(
                filePath: filePath,
                lowerRange: 0,
                upperRange: prefetchLimit
            )
            
            do {
                let (response, data) = try await networkService.downloadVideo(router)
                
                guard let httpResponse = response, let prefetchedData = data else { return }
                
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
                    let cache = ShortVideoPrefetchCache(
                        videoID: id,
                        totalLength: totalLength,
                        contentType: contentType,
                        data: prefetchedData
                    )
                    
                    // 캐시 저장
                    cacheService.saveCache(for: id, cache: cache)
                }
                
            } catch {
                if !(error is CancellationError) {
                    print("❌ [Prefetch] \(video.files.first!) 다운로드 실패: \(error)")
                }
            }
            self.activeTasks[id] = nil
        }
        activeTasks[id] = task
    }
    
    func cancelPrefetch(videoID: String) {
        activeTasks[videoID]?.cancel()
        activeTasks[videoID] = nil
    }
    
    func cancelAndRemoveCache(videoID: String) {
        cancelPrefetch(videoID: videoID)
        cacheService.removeCache(for: videoID)
    }
    
    func getPrefetchData(videoID: String) -> ShortVideoPrefetchCache? {
        return cacheService.getCache(for: videoID)
    }
    
    func getCachedSize(videoID: String) -> Int64 {
        if let cache = cacheService.getCache(for: videoID) {
            return Int64(cache.data.count)
        }
        return 0
    }
}
