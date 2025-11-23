//
//  VideoDownloadRouter.swift
//  FlatBread
//
//  Created by 김민성 on 11/20/25.
//

import AVFoundation
import Foundation
import Alamofire

enum VideoDownloadRouter: VideoStreamableRouter {
    
    case downloadVideos(loadingRequest: AVAssetResourceLoadingRequest, filePath: String)
    case streamVideo(filePath: String, lowerRange: Int64, upperRange: Int64?)
    
    var baseURL: URL {
        guard let url = URL(string: APIConfig.baseURL) else {
            assert(false, "is not valid Video Downloading URL")
        }
        return url
    }
    
    var method: Alamofire.HTTPMethod {
        return .get
    }
    
    var path: String {
        switch self {
        case .downloadVideos(_, let filePath), .streamVideo(let filePath, _, _):
            return filePath
        }
    }
    
    var headers: Alamofire.HTTPHeaders {
        switch self {
        case .downloadVideos(let loadingRequest, _):
            let apiHeaderTypes: [APIHeader] = [.apiKey, .productID]
            var headerTypes: [HTTPHeader] = []
            let dataRequest = loadingRequest.dataRequest
            if let dataRequest {
                let lower = dataRequest.requestedOffset
                let upper = lower + Int64(dataRequest.requestedLength) - 1
                let rangeHeaderValue = "bytes=\(lower)-\(upper)"
                let rangeHeader = HTTPHeader(name: "Range", value: rangeHeaderValue)
                headerTypes.append(rangeHeader)
                print("Range 요청: \(rangeHeaderValue)")
                print("requestedOffset: \(dataRequest.requestedOffset)")
            }
            return HTTPHeaders(apiHeaderTypes.map(\.httpHeader) + headerTypes)
            
        case .streamVideo(_, let lowerRange, let upperRange):
            let apiHeaderTypes: [APIHeader] = [.apiKey, .productID]
            var headerTypes: [HTTPHeader] = []
            
            let rangeHeaderValue: String
            if let upperRange {
                rangeHeaderValue = "bytes=\(lowerRange)-\(upperRange)"
            } else {
                rangeHeaderValue = "bytes=\(lowerRange)-"
            }
            let rangeHeader = HTTPHeader(name: "Range", value: rangeHeaderValue)
            headerTypes.append(rangeHeader)
            print("Range 요청: \(rangeHeaderValue)")
            return HTTPHeaders(apiHeaderTypes.map(\.httpHeader) + headerTypes)
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        switch self {
        case .downloadVideos, .streamVideo:
            guard let url = URL(string: self.baseURL.appendingPathComponent(self.path).absoluteString) else {
                throw URLError(.badURL)
            }
            var request = URLRequest(url: url)
            request.method = self.method
            request.headers = self.headers
            return request
        }
    }
    
    func asURL() throws -> URL {
        if let url = URL(string: self.baseURL.appendingPathComponent(self.path).absoluteString) {
            return url
        } else {
            throw NetworkError.invalidURL
        }
    }
    
}
