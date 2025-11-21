import Foundation
import AVFoundation
import UniformTypeIdentifiers

class CustomResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    var videoFilePath: String? = nil
    
    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        guard let videoFilePath else { return false }
        Task {
            do {
                let networkRouter = VideoDownloadRouter.downloadVideos(
                    loadingRequest: loadingRequest,
                    filePath: videoFilePath
                )
                let (urlResponse, data) = try await networkService.downloadVideo(networkRouter)
                handleVideoData(data: data, httpResponse: urlResponse, loadingRequest: loadingRequest)
            } catch {
                print("동영상 다운로드 에러")
            }
        }
        
        return true
    }
    
    private func handleVideoData(data: Data?, httpResponse: HTTPURLResponse?, loadingRequest: AVAssetResourceLoadingRequest) {
        guard let data, let httpResponse else {
            loadingRequest.finishLoading(with: NetworkError.invalidResponse)
            return
        }
        
        if let contentInfo = loadingRequest.contentInformationRequest {
            if let mimeType = httpResponse.mimeType {
                if let utType = UTType(mimeType: mimeType) {
                    contentInfo.contentType = utType.identifier
                } else {
                    contentInfo.contentType = "public.mpeg-4"
                }
            }
            contentInfo.isByteRangeAccessSupported = true
            
            // 헤더 키가 대소문자가 섞여 있을 수 있으므로 둘 다 체크
            let rangeHeader = (httpResponse.allHeaderFields["Content-Range"] as? String) ??
            (httpResponse.allHeaderFields["content-range"] as? String)
            
            if let rangeHeader = rangeHeader {
                // 형식: "bytes 0-1/1234567" -> "/" 뒤의 숫자(1234567)가 전체 길이
                let components = rangeHeader.components(separatedBy: "/")
                if components.count > 1,
                   let totalLengthString = components.last?.trimmingCharacters(in: .whitespaces),
                   let totalLength = Int64(totalLengthString) {
                    
                    contentInfo.contentLength = totalLength
                    print("[Info] 전체 길이 파싱 성공: \(totalLength) (헤더: \(rangeHeader))")
                    
                } else {
                    // 파싱 실패 시
                    print("[Warning] Range 헤더 파싱 실패, Chunk 크기 사용: \(rangeHeader)")
                    contentInfo.contentLength = httpResponse.expectedContentLength
                }
            } else {
                // Range 헤더가 없으면 (200 OK 응답인 경우) Content-Length가 전체 길이
                contentInfo.contentLength = httpResponse.expectedContentLength
                print("[Info] Range 헤더 없음, 전체 다운로드 모드: \(httpResponse.expectedContentLength)")
            }
        }
        
        if let dataRequest = loadingRequest.dataRequest {
            dataRequest.respond(with: data)
            print("[Data] 요청된 조각 전달: \(data.count) bytes (Offset: \(dataRequest.requestedOffset))")
        }
        
        loadingRequest.finishLoading()
    }
    
}
