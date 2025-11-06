//
//  Router.swift
//  FlatBread
//
//  Created by hwan on 11/6/25.
//

import Foundation
import Alamofire

struct FollowRouter: URLRequestConvertible {
    let userID: String
    var baseURL: URL {
        URL(string: APIConfig.baseURL)!
    }
    var path: String {
        "/follow/\(userID)"
    }
    var isFollow: Bool
    
    init(userID: String, isFollow: Bool) {
        self.userID = userID
        self.isFollow = isFollow
    }
    
    func asURLRequest() throws -> URLRequest {
        var request = URLRequest(url: baseURL)
        request.method = .post
        request.headers = HTTPHeaders(
            [
                APIHeader.applicationJSON,
                APIHeader.apiKey, APIHeader.productID,
                APIHeader.accessToken
            ].map(\.httpHeader)
        )
        request.httpBody = try? JSONEncoder().encode(["follow_status": self.isFollow])
        return request
    }
}
