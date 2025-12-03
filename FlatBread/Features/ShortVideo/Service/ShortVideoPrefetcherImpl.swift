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
    
    private let prefetchPrevCount = 3
    private let prefetchNextCount = 4
    private let keepPrevCount = 7
    private let keepNexCount = 7
    private let prefetchLimit: Int64 = 2 * 1024 * 1024 // 2MB
    
    init(cacheService: ShortVideoCacheService, networkService: AsyncNetworkService) {
        self.cacheService = cacheService
        self.networkService = networkService
    }
    
    func updatePrefetchWindow(around currentIndex: Int, in fullList: [ShortVideo]) {
        print("프리패치 윈도우 업데이트. Index: \(currentIndex)")
        
        let prefetchStart = max(0, currentIndex - prefetchPrevCount)
        let prefetchEnd = min(fullList.count - 1, currentIndex + prefetchNextCount)
        
        for index in prefetchStart...prefetchEnd {
            guard index != currentIndex else { continue }
            let video = fullList[index]
            self.startPrefetch(video: video)
        }
        
        let keepStart = max(0, currentIndex - keepPrevCount)
        let keepEnd = min(fullList.count - 1, currentIndex + keepNexCount)
        
        for (index, video) in fullList.enumerated() {
            if index < keepStart || index > keepEnd {
                self.cancelAndRemoveCache(videoID: video.id)
            }
        }
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
    
    private func startPrefetch(video: ShortVideo) {
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
    
    private func cancelPrefetch(videoID: String) {
        activeTasks[videoID]?.cancel()
        activeTasks[videoID] = nil
    }
    
    private func cancelAndRemoveCache(videoID: String) {
        cancelPrefetch(videoID: videoID)
        cacheService.removeCache(for: videoID)
    }
    
}
