//
//  Router.swift
//  FlatBread
//
//  Created by hwan on 11/6/25.
//

import Foundation
import Alamofire

struct FollowRouter: APIRouter {
    var method: HTTPMethod = .post
    
    var headers: HTTPHeaders = HTTPHeaders(
        [
            APIHeader.applicationJSON,
            APIHeader.apiKey,
            APIHeader.productID
        ].map(\.httpHeader)
    )
    
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
        request.method = self.method
        request.headers = self.headers
        request.httpBody = try? JSONEncoder().encode(["follow_status": self.isFollow])
        return request
    }
}
