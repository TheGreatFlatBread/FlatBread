import Foundation
import AVFoundation
import UniformTypeIdentifiers
import Alamofire

class CustomResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    var videoFilePath: String? = nil
    
    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        guard let videoFilePath else { return false }
        guard let dataRequest = loadingRequest.dataRequest else {
            return false
        }
        
        let lower = dataRequest.currentOffset
        var upperRange: Int64? = nil
        if !dataRequest.requestsAllDataToEndOfResource {
            upperRange = lower + Int64(dataRequest.requestedLength) - 1
        }
        let router = VideoDownloadRouter.streamVideo(
            filePath: videoFilePath,
            lowerRange: lower,
            upperRange: upperRange
        )
        
        #if DEBUG
        var log = "🔄 [AVPlayer] 요청 들어옴. range: \(lower)-"
        if let upperRange { log += String(upperRange) }
        print(log)
        #endif
        
        networkService.streamVideo(
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
                        print("❌ 스트리밍 중 에러: \(error)")
                        loadingRequest.finishLoading(with: error)
                    }
                case .complete(let completion):
                    if let error = completion.error {
                        print("❌ 다운로드 완료 실패: \(error)")
                        loadingRequest.finishLoading(with: error)
                    } else {
                        print("✅ 다운로드 및 전달 완료")
                        loadingRequest.finishLoading()
                    }
                }
            }
        )
        return true
    }
    
#if DEBUG
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        guard let dataRequest = loadingRequest.dataRequest else {
            return
        }
        
        let lower = dataRequest.currentOffset
        var upperRange: Int64? = nil
        if !dataRequest.requestsAllDataToEndOfResource {
            upperRange = lower + Int64(dataRequest.requestedLength) - 1
        }
        var log = "🔄 [AVPlayer] 요청 들어옴. range: \(lower)-"
        if let upperRange { log += String(upperRange) }
        print(log)
    }
#endif
    
    
    private func fillContentInfo(loadingRequest: AVAssetResourceLoadingRequest, response: HTTPURLResponse?) {
        guard let contentInfo = loadingRequest.contentInformationRequest,
              let httpResponse = response,
              contentInfo.contentType == nil
        else {
            return
        }
        
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
