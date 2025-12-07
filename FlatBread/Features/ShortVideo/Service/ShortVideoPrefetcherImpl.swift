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
    
    // MARK: - Dependencies
    private let cacheService: ShortVideoCacheService
    private let networkService: AsyncNetworkService
    
    // MARK: - Properties
    private var activeOperations: [String: Operation] = [:]
    
    private let prefetchQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.flatbread.shortvideo.prefetchQueue"
        queue.maxConcurrentOperationCount = 2
        queue.qualityOfService = .utility
        return queue
    }()
    
    // MARK: - Configuration
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
        let prefetchWindow = (currentIndex - prefetchPrevCount)...(currentIndex + prefetchNextCount)
        let keepWindow = (currentIndex - keepPrevCount)...(currentIndex + keepNexCount)
        let videoIdSet = Set(fullList.map(\.id))
        
        // activeOperations의 취소 로직
        for (videoID, operation) in activeOperations {
            // 현재 비디오 배열에 존재하지 않는 비디오의 Operation은 취소
            guard videoIdSet.contains(videoID) else {
                operation.cancel()
                activeOperations[videoID] = nil
                continue
            }
            
            if let index = fullList.firstIndex(where: { $0.id == videoID }) {
                // 현재 작업 중이 operation이 prefetchWindow에 포함되지 않는다면 작업을 취소
                if !prefetchWindow.contains(index) {
                    operation.cancel()
                    activeOperations[videoID] = nil
                }
                // activeOperations이 작업 중인 비디오의 index가 keepWindow에 포함되지 않는다면 캐시 삭제
                if !keepWindow.contains(index) {
                    cacheService.removeCache(for: videoID)
                }
            }
        }
        
        // where 절은 0 미만, 최댓값 초과를 막는 로직
        for index in prefetchWindow where fullList.indices.contains(index) {
            if index == currentIndex { continue }
            
            let video = fullList[index]
            
            if cacheService.isCached(for: video.id) { continue }
            if activeOperations[video.id] != nil { continue }
            
            guard let operation = createPrefetchOperation(for: video) else {
                print("[Prefetch] ShortVideo의 files가 비어있어서 Operation 생성 불가")
                continue
            }
            
            let distance = abs(index - currentIndex)
            if distance == 1 {
                operation.queuePriority = .veryHigh
            } else if distance <= 3 {
                operation.queuePriority = .high
            } else {
                operation.queuePriority = .normal
            }
            
            activeOperations[video.id] = operation
            prefetchQueue.addOperation(operation)
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
    
    // MARK: - Private Helper Methods
    
    private func createPrefetchOperation(for video: ShortVideo) -> Operation? {
        guard let filePath = video.files.first else { return nil }
        let operation = PrefetchOperation(videoID: video.id, filePath: filePath, prefetcher: self)
        operation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                self?.activeOperations[video.id] = nil
            }
        }
        return operation
    }
    
    fileprivate func performPrefetch(videoID: String, filePath: String) async {
        let router = VideoDownloadRouter.streamVideo(
            filePath: filePath,
            lowerRange: 0,
            upperRange: prefetchLimit
        )
        
        do {
            try Task.checkCancellation()
            let (response, data) = try await networkService.downloadVideo(router)
            try Task.checkCancellation()
            guard !Task.isCancelled, let httpResponse = response, let prefetchedData = data else { return }
            
            let contentType = httpResponse.mimeType ?? "public.mpeg-4"
            var totalLength: Int64 = httpResponse.expectedContentLength
            
            if let rangeHeader = httpResponse.allHeaderFields["Content-Range"] as? String ??
                                 httpResponse.allHeaderFields["content-range"] as? String,
               let totalStr = rangeHeader.components(separatedBy: "/").last?.trimmingCharacters(in: .whitespaces),
               let length = Int64(totalStr) {
                totalLength = length
            }
            guard totalLength > 0 else { return }
            let cache = ShortVideoPrefetchCache(
                videoID: videoID,
                totalLength: totalLength,
                contentType: contentType,
                data: prefetchedData
            )
            
            try Task.checkCancellation()
            cacheService.saveCache(for: videoID, cache: cache)
        } catch is CancellationError {
            print("[Prefetch] 작업 취소됨(Task Cancelled): \(videoID)")
        } catch {
            print("[Prefetch] \(filePath) 다운로드 중 에러: \(error)")
        }
    }
    
}


// MARK: - Nested Type (Operation)
fileprivate extension ShortVideoPrefetcherImpl {
    
    /// 비동기 `Task`를 래핑 및 `Operation`의 생명주기와 `Task`의 취소를 동기화하기 위해 정의한 Operation
    final class PrefetchOperation: Operation, @unchecked Sendable {
        private var task: Task<Void, Never>?
        private let videoID: String
        private let filePath: String
        
        // `performPrefetch` 호출하기 위함...
        // TODO: ShortVideoPrefetcherImpl 및 관련 프로토콜들에 Sendable 처리 필요
        private weak var prefetcher: ShortVideoPrefetcherImpl?
        
        init(videoID: String, filePath: String, prefetcher: ShortVideoPrefetcherImpl) {
            self.videoID = videoID
            self.filePath = filePath
            self.prefetcher = prefetcher
            super.init()
        }
        
        override func main() {
            if isCancelled { return }
            
            // Task의 동작이 끝날 때까지 main 함수를 기다리기 위해 Semaphore 사용
            let semaphore = DispatchSemaphore(value: 0)
            self.task = Task {
                await prefetcher?.performPrefetch(videoID: videoID, filePath: filePath)
                semaphore.signal()
            }
            semaphore.wait()
        }
        
        override func cancel() {
            super.cancel()
            task?.cancel()
        }
    }
    
}
