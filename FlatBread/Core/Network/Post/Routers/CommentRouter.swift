//
//  CommentRouter.swift
//  FlatBread
//
//  Created by hwan on 11/6/25.
//

import Foundation
import Alamofire

enum CommentRouter: URLRequestConvertible {
    static let encoder = JSONEncoder()
    
    case getCommentList(postID: String)
    case writeComment(postID: String, content: String)
    case updateComment(postID: String, commentID: String, content: String)   // comment and sub-comment
    case deleteComment(postID: String, commentID: String)
    case writeSubComment(postID: String, commentID: String, content: String)

    var baseURL: URL {
        if let url = URL(string: APIConfig.baseURL + "/posts") {
            return url
        } else {
            assert(false, "is not valid User URL")
        }
    }
    
    var method: HTTPMethod {
        return switch self {
        case .getCommentList: .get
        case .writeComment, .writeSubComment: .post
        case .updateComment: .put
        case .deleteComment: .delete
        }
    }
    
    var headers: HTTPHeaders {
        switch self {
        default:
            let headerTypes: [APIHeader] = [.applicationJSON, .apiKey, .productID, .accessToken]
            return HTTPHeaders(headerTypes.map(\.httpHeader))
        }
    }
    
    var path: String {
        return switch self {
        case .getCommentList(let postID): 
            "\(postID)/comments"
        case .writeComment(let postID, _):
            "\(postID)/comments"
        case .updateComment(let postID, let commentID, _):
            "\(postID)/comments/\(commentID)"
        case .deleteComment(let postID, let commentID): 
            "\(postID)/comments/\(commentID)"
        case .writeSubComment(let postID, let commentID, _):
            "\(postID)/comments/\(commentID)/replies"
        }
    }
    
    var body: Data? {
        return switch self {
        case .writeComment(_, let content),
             .updateComment(_, _, let content),
             .writeSubComment(_, _, let content):
            try? Self.encoder.encode(["content": content])
        default: nil
        }
    }
    
    var query: [URLQueryItem]? {
        switch self {
        default:
            return nil
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        var components = URLComponents(string: self.baseURL.appendingPathComponent(self.path).absoluteString)!
        if let query = self.query {
            components.queryItems = self.query
        }
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.method = self.method
        request.headers = self.headers
        request.httpBody = self.body
        return request
    }
}
