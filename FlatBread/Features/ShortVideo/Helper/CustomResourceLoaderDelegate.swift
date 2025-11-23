import Foundation
import AVFoundation
import UniformTypeIdentifiers
import Alamofire

class CustomResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    weak var shortVideo: ShortVideo?
    var videoFilePath: String? = nil
    
    private let cacheService = ShortVideoCacheService.shared
    private var activeRequest: DataStreamRequest? // 현재 플레이어 재생용 요청
    
    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        guard let videoFilePath else { return false }
        guard let dataRequest = loadingRequest.dataRequest, let shortVideo else {
            return false
        }
        
        let lower = dataRequest.requestedOffset
        let requestedOffset = dataRequest.requestedOffset
        let requestedLength = Int64(dataRequest.requestedLength)
        var upperRange: Int64? = nil
        if !dataRequest.requestsAllDataToEndOfResource {
            upperRange = lower + Int64(dataRequest.requestedLength) - 1
        }
        
        let cachedSize = cacheService.getCachedSize(for: shortVideo.id)
        let fileURL = cacheService.getFileURL(for: shortVideo.id)
        
        if loadingRequest.contentInformationRequest != nil {
            fillContentInfo(loadingRequest: loadingRequest, response: nil)
        }
        
        #if DEBUG
        var log = "🔄 [AVPlayer] 요청 들어옴. id: \(shortVideo.id), range: \(lower)-"
        if let upperRange { log += String(upperRange) }
        print(log)
        #endif
        
        // 로컬 캐시 Hit
        if requestedOffset < cachedSize,
           cacheService.checkCacheExist(for: shortVideo.id) {
            
            print("💾 [Delegate] 로컬 캐시 사용: \(shortVideo.id) (Offset: \(requestedOffset))")
            fillContentInfo(loadingRequest: loadingRequest, response: nil)
            do {
                let fileHandle = try FileHandle(forReadingFrom: fileURL)
                defer { try? fileHandle.close() }
                
                try fileHandle.seek(toOffset: UInt64(requestedOffset))
                
                let availableBytes = cachedSize - requestedOffset
                let lengthToRead = min(availableBytes, requestedLength)
                
                let data = fileHandle.readData(ofLength: Int(lengthToRead))
                loadingRequest.dataRequest?.respond(with: data)
                loadingRequest.finishLoading()
                return true
            } catch {
                print("❌ 파일 읽기 실패")
            }
        }
        
        if loadingRequest.isFinished { return true }
        
        let startOffset = max(requestedOffset, cachedSize)
        let router = VideoDownloadRouter.streamVideo(
            filePath: videoFilePath,
            lowerRange: startOffset,
            upperRange: upperRange
        )
        
        activeRequest = networkService.streamVideo(
            router,
            responseHandler: { [weak self] httpResponse in
                guard let self else { return }
                self.fillContentInfo(loadingRequest: loadingRequest, response: httpResponse)
            },
            dataHandler: { stream in
                switch stream.event {
                case .stream(let result):
                    switch result {
                    case .success(let data):
                        loadingRequest.dataRequest?.respond(with: data)
                    case .failure(let error):
                        print("❌ 스트리밍 중 에러: \(error), id: \(self.shortVideo!.id)")
                        loadingRequest.finishLoading(with: error)
                    }
                case .complete(let completion):
                    if let error = completion.error {
                        print("❌ 다운로드 완료 실패: \(error), id: \(self.shortVideo!.id)")
                        loadingRequest.finishLoading(with: error)
                    } else {
                        print("✅ 다운로드 및 전달 완료, id: \(self.shortVideo!.id)")
                        loadingRequest.finishLoading()
                    }
                }
            }
        )
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        activeRequest?.cancel()
        #if DEBUG
        guard let dataRequest = loadingRequest.dataRequest else {
            return
        }
        
        let lower = dataRequest.currentOffset
        var upperRange: Int64? = nil
        if !dataRequest.requestsAllDataToEndOfResource {
            upperRange = lower + Int64(dataRequest.requestedLength) - 1
        }
        var log = "🔄 [AVPlayer] 요청 취소됨. range: \(lower)-"
        if let upperRange { log += String(upperRange) }
        print(log)
        #endif
    }
    
    
    private func fillContentInfo(loadingRequest: AVAssetResourceLoadingRequest, response: HTTPURLResponse?) {
        guard let contentInfo = loadingRequest.contentInformationRequest else { return }
        
        // httpResponse가 있을 경우 먼저 시도
        if let httpResponse = response {
            if let mimeType = httpResponse.mimeType, let utType = UTType(mimeType: mimeType) {
                contentInfo.contentType = utType.identifier
            } else {
                contentInfo.contentType = "public.mpeg-4"
            }
            
            contentInfo.isByteRangeAccessSupported = true
            
            // 전체 길이(Content-Length) 파싱
            let rangeHeader = (httpResponse.allHeaderFields["Content-Range"] as? String) ??
            (httpResponse.allHeaderFields["content-range"] as? String)
            
            if let rangeHeader {
                let components = rangeHeader.components(separatedBy: "/")
                if components.count > 1,
                   let totalLengthString = components.last?.trimmingCharacters(in: .whitespaces),
                   let totalLength = Int64(totalLengthString) {
                    contentInfo.contentLength = totalLength
                }
            } else {
                contentInfo.contentLength = httpResponse.expectedContentLength
            }
        }
        
        // httpResponse가 없을 경우 프리로딩 시에 저장한 UserDefaults에서 검색
        if let videoID = shortVideo?.id {
            let savedLength = UserDefaults.standard.integer(forKey: "\(videoID)_totalLength")
            let savedType = UserDefaults.standard.string(forKey: "\(videoID)_contentType")
            
            if savedLength > 0 {
                contentInfo.contentLength = Int64(savedLength)
                contentInfo.contentType = savedType ?? "public.mpeg-4"
                contentInfo.isByteRangeAccessSupported = true
                // print("ℹ️ [Delegate] 저장된 메타데이터 적용: \(savedLength) bytes")
                return
            }
        }
        
        // httpResponse도 없고 UserDefaults에도 없는 경우 임의 값 할당.
        contentInfo.contentType = "public.mpeg-4"
        contentInfo.isByteRangeAccessSupported = true
        contentInfo.contentLength = 100_000_000 // 임시 큰 값 (이래도 괜찮은 건지는 모르겠음..)
    }
    
}
