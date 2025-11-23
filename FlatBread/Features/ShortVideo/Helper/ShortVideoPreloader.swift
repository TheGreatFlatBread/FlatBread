//
//  ShortVideoPreloader.swift
//  FlatBread
//
//  Created by 김민성 on 11/23/25.
//

import Foundation
import Alamofire

final class ShortVideoPreloader {
    static let shared = ShortVideoPreloader()
    
    private let cacheService = ShortVideoCacheService.shared
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    
    // 프리로딩 중인 작업들
    private var preloadingRequests: [String: DataStreamRequest] = [:]
    private let preloadLimit: Int64 = 2 * 1000 * 1000 // 2MB
    
    func startPreload(video: ShortVideo) {
        let id = video.id
        
        // 이미 프리로딩 작업 중이거나, 2MB 이상 캐시되어 있으면 패스
        if preloadingRequests[id] != nil { return }
        let currentSize = cacheService.getCachedSize(for: id)
        if currentSize >= preloadLimit { return }
        
        let fileURL = cacheService.getFileURL(for: id)
        
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }
        
        guard let fileHandle = try? FileHandle(forWritingTo: fileURL) else { return }
        
        // 파일 끝으로 이동 (이어받기 지원을 위해)
        try? fileHandle.seekToEnd()
        let startOffset = currentSize // 이미 받은 만큼 건너뛰고 요청
        
        guard let filePath = video.files.first else {
            return
        }
        let networkRouter = VideoDownloadRouter.streamVideo(
            filePath: filePath,
            lowerRange: startOffset,
            upperRange: startOffset + preloadLimit
        )
        
        let request = networkService.streamVideo(
            networkRouter,
            responseHandler: { [weak self] httpResponse in
                guard let self else { return }
                self.saveVideoMetadata(id: id, response: httpResponse)
            },
            dataHandler: { [weak self] stream in
                guard let self else { return }
                switch stream.event {
                case .stream(let result):
                    switch result {
                    case .success(let data):
                        try? fileHandle.write(contentsOf: data)
                        let currentLength = (try? fileHandle.offset()) ?? 0
                        if currentLength >= self.preloadLimit {
                            print("[Preloader] \(id) - 2MB 도달. 프리로딩 중지.")
                            cancelPreload(videoID: id)
                        }
                    }
                case .complete:
                    try? fileHandle.close()
                    self.preloadingRequests[id] = nil
                }
            }
        )
        
        preloadingRequests[id] = request
        print("[Preloader] \(id) 프리로딩 시작")
    }
    
    func cancelPreload(videoID: String) {
        if let request = preloadingRequests[videoID] {
            request.cancel()
            preloadingRequests[videoID] = nil
        }
    }
    
    func cancelAll() {
        preloadingRequests.values.forEach { $0.cancel() }
        preloadingRequests.removeAll()
    }
    
    // 프리로딩 시 헤더에서 받아오는 Content-Range나 mimeType 등을 UserDefaults에 저장
    private func saveVideoMetadata(id: String, response: HTTPURLResponse) {
        let contentType = response.mimeType ?? "public.mpeg-4"
        
        // 전체 길이 추출 로직
        var totalLength: Int64 = response.expectedContentLength
        
        let rangeHeader = (response.allHeaderFields["Content-Range"] as? String) ??
        (response.allHeaderFields["content-range"] as? String)
        if let rangeHeader {
            let components = rangeHeader.components(separatedBy: "/")
            if components.count > 1,
               let totalLengthString = components.last?.trimmingCharacters(in: .whitespaces),
               let length = Int64(totalLengthString) {
                totalLength = length
            }
        }
        
        if totalLength > 0 {
            UserDefaults.standard.set(totalLength, forKey: "\(id)_totalLength")
            UserDefaults.standard.set(contentType, forKey: "\(id)_contentType")
        }
    }
    
    func cancelAndRemoveCache(videoID: String) {
        cancelPreload(videoID: videoID)
        cacheService.removeCacheFile(for: videoID)
        
        UserDefaults.standard.removeObject(forKey: "\(videoID)_totalLength")
        UserDefaults.standard.removeObject(forKey: "\(videoID)_contentType")
    }
    
}
