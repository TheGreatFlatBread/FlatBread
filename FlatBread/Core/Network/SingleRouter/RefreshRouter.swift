//
//  RefreshRouter.swift
//  FlatBread
//
//  Created by hwan on 11/6/25.
//

import Foundation
import Alamofire

struct RefreshRouter: APIRouter {
    var method: HTTPMethod = .get
    
    var headers: HTTPHeaders = HTTPHeaders(
        [
            APIHeader.applicationJSON,
            APIHeader.apiKey,
            APIHeader.productID,
        ].map(\.httpHeader)
    )
    
    let refreshToken: String
    let accessToken: String
    
    var baseURL: URL {
        URL(string: APIConfig.baseURL + path)!
    }
    var path: String {
        "/auth/refresh"
    }
    
    init(accessToken: String, refreshToken: String) {
        self.refreshToken = refreshToken
        self.accessToken = accessToken
    }
    
    func asURLRequest() throws -> URLRequest {
        var request = URLRequest(url: baseURL)
        request.method = self.method
        var headers = self.headers
        headers.add(HTTPHeader(name: "RefreshToken", value: refreshToken))
        headers.add(HTTPHeader(name: "Authorization", value: accessToken))
        request.headers = headers
        return request
    }
}
