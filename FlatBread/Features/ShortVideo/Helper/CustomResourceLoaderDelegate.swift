import Foundation
import AVFoundation
import UniformTypeIdentifiers
import Alamofire

class CustomResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    
    weak var shortVideo: ShortVideo?
    var videoFilePath: String? = nil
    
    var preloader: ShortVideoPreloader?
    
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    private var activeRequest: DataStreamRequest? // 현재 플레이어 재생용 요청
    
    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        guard let videoFilePath else { return false }
        guard let dataRequest = loadingRequest.dataRequest, let shortVideo else { return false }
        
        let lower = dataRequest.requestedOffset
        let requestedOffset = dataRequest.requestedOffset
        let requestedLength = Int64(dataRequest.requestedLength)
        var upperRange: Int64? = nil
        if !dataRequest.requestsAllDataToEndOfResource {
            upperRange = lower + Int64(dataRequest.requestedLength) - 1
        }
        
        let cachedSize = preloader?.getCachedSize(videoID: shortVideo.id) ?? 0
        
        // ContentInfo 채우기
        if let cache = preloader?.getPreloadData(videoID: shortVideo.id) {
            print("\(shortVideo.files.first!) 캐시가 발견되어 contentInfo를 채웁니다.")
            fillContentInfo(loadingRequest: loadingRequest, cache: cache)
        } else {
            print("\(shortVideo.files.first!) 캐시가 없어 contentInfo를 임시로 채웁니다.")
            if loadingRequest.contentInformationRequest != nil {
                loadingRequest.contentInformationRequest?.contentType = "public.mpeg-4"
                loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true
                loadingRequest.contentInformationRequest?.contentLength = 100_000_000
            }
        }
        
#if DEBUG
        var log = "🔄 [AVPlayer] 요청 들어옴. id: \(shortVideo.id), range: \(lower)-"
        if let upperRange { log += String(upperRange) }
        print(log)
#endif
        
        // 캐시 조회
        if let cache = preloader?.getPreloadData(videoID: shortVideo.id),
           requestedOffset < cachedSize {
            
            print("💾 [Delegate] 캐시 히트: \(shortVideo.id)")
            
            let dataCount = Int64(cache.data.count)
            let availableBytes = dataCount - requestedOffset
            let lengthToRead = min(availableBytes, requestedLength)
            
            // Data slicing
            let startIndex = Int(requestedOffset)
            let endIndex = startIndex + Int(lengthToRead)
            let chunk = cache.data[startIndex..<endIndex]
            
            dataRequest.respond(with: chunk)
            loadingRequest.finishLoading()
            return true
        }
        
        if loadingRequest.isFinished { return true }
        
        print("\(shortVideo.files.first!) 캐시가 없어서 네트워크에서 스트리밍으로 받아옵니다.")
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
                self.fillContentInfo(loadingRequest: loadingRequest, httpResponse: httpResponse)
            },
            dataHandler: { stream in
                switch stream.event {
                case .stream(let result):
                    switch result {
                    case .success(let data):
                        loadingRequest.dataRequest?.respond(with: data)
                    case .failure(let error):
                        print("❌ 스트리밍 중 에러: \(error), id: \(shortVideo.id)")
                        loadingRequest.finishLoading(with: error)
                    }
                case .complete(let completion):
                    if let error = completion.error {
                        print("❌ 다운로드 완료 실패: \(error), id: \(shortVideo.id)")
                        loadingRequest.finishLoading(with: error)
                    } else {
                        print("✅ 다운로드 및 전달 완료, id: \(shortVideo.id)")
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
    
}

// contentInfo 설정 관련
private extension CustomResourceLoaderDelegate {
    
    // 캐시를 사용하여 contentInfo를 채움.
    func fillContentInfo(loadingRequest: AVAssetResourceLoadingRequest, cache: ShortVideoPreloadCache) {
        guard let info = loadingRequest.contentInformationRequest else { return }
        info.contentType = cache.contentType
        info.contentLength = cache.totalLength
        info.isByteRangeAccessSupported = true
    }
    
    // 네트워크 응답값을 사용하여 contentInfo를 채움.
    func fillContentInfo(loadingRequest: AVAssetResourceLoadingRequest, httpResponse: HTTPURLResponse) {
        guard let contentInfo = loadingRequest.contentInformationRequest else { return }
        
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
    
}
