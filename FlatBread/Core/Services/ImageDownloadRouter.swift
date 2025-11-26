//
//  ImageDownloadRouter.swift
//  FlatBread
//
//  Created by hwan on 11/25/25.
//

import Foundation
import Alamofire

enum ImageDownloadRouter: DownloadAPIRouter {
    case downloadImage(path: String)

    var baseURL: URL {
        URL(string: APIConfig.baseURL)!
    }

    var method: HTTPMethod {
        .get
    }

    var path: String {
        switch self {
        case .downloadImage(let imagePath):
            return imagePath.hasPrefix("/") ? String(imagePath.dropFirst()) : imagePath
        }
    }

    var headers: HTTPHeaders {
        let headerTypes: [APIHeader] = [.apiKey, .productID]
        return HTTPHeaders(headerTypes.map(\.httpHeader))
    }

    var body: Data? {
        nil
    }

    var query: [URLQueryItem]? {
        nil
    }

    var destination: DownloadRequest.Destination {
        let destination: DownloadRequest.Destination = { _, _ in
            let documentsURL = FileManager.default.temporaryDirectory
            let fileURL = documentsURL.appendingPathComponent(UUID().uuidString)
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        return destination
    }

    func asURLRequest() throws -> URLRequest {
        var components = URLComponents(string: baseURL.appendingPathComponent(path).absoluteString)!
        components.queryItems = query
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.method = method
        request.headers = headers
        request.httpBody = body
        return request
    }
}
