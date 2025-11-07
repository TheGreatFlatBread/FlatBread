//
//  RefreshRouter.swift
//  FlatBread
//
//  Created by hwan on 11/6/25.
//

import Foundation
import Alamofire

struct RefreshRouter: APIRouter {
    var method: HTTPMethod = .post
    
    var headers: HTTPHeaders = HTTPHeaders(
        [
            APIHeader.applicationJSON,
            APIHeader.apiKey,
            APIHeader.productID,
        ].map(\.httpHeader)
    )
    
    let refreshToken: String
    var baseURL: URL {
        URL(string: APIConfig.baseURL)!
    }
    var path: String {
        "/auth/refresh"
    }
    
    init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
    
    func asURLRequest() throws -> URLRequest {
        var request = URLRequest(url: baseURL)
        request.method = self.method
        var headers = self.headers
        headers.add(HTTPHeader(name: "RefreshToken", value: refreshToken))
        request.headers = headers
        return request
    }
}
