//
//  PostRouter.swift
//  FlatBread
//
//  Created by hwan on 11/5/25.
//

import Foundation
import Alamofire

enum PostRouter: APIRouter {
    static let encoder = JSONEncoder()
    
    case uploadPost(request: PostUploadRequestDTO)
    case getPostList(next: String, limit: String, category: [String])
    case getPost(postID: String)
    case updatePost(postID: String, request: PostUploadRequestDTO)
    case deletePost(postID: String)
    case togglePostLikeV1(postID: String, like_status: Bool)
    case togglePostLikeV2(postID: String, like_status: Bool)
    case getMeLikePostListV1(next: String, limit: String, category: [String])
    case getMeLikePostListV2(next: String, limit: String, category: [String])
    case getUserPostList(userID: String, next: String, limit: String, category: [String])
    case searchHashTagList(next: String, limit: String, category: [String], hashTag: String)
    case searchFollowFeedList(next: String, limit: String, category: [String])
    case searchGeolocationPostList(category: [String], longitude: String, latitude: String, maxDistance: String, order_by: GeoSortBy = .distance, sort_by: SortBy = .asc)
    case searchPostTitle(title: String, category: [String])

    enum GeoSortBy: String {
        case distance
        case createdAt
    }
    
    enum SortBy: String {
        case asc, desc
    }

    var baseURL: URL {
        if let url = URL(string: APIConfig.baseURL + "/posts/") {
            return url
        } else {
            assert(false, "is not valid User URL")
        }
    }
    
    var method: HTTPMethod {
        return switch self {
        case .uploadPost, .togglePostLikeV1, .togglePostLikeV2: .post
        case .updatePost: .put
        case .deletePost: .delete
        default: .get
        }
    }
    
    var headers: HTTPHeaders {
        switch self {
        default:
            let headerTypes: [APIHeader] = [.applicationJSON, .apiKey, .productID]
            return HTTPHeaders(headerTypes.map(\.httpHeader))
        }
    }
    
    var path: String {
        return switch self {
        case .uploadPost: ""
        case .getPostList: ""
        case .getPost(let id), .updatePost(let id, _), .deletePost(let id): "\(id)"
        case .togglePostLikeV1(let id, _): "\(id)/like"
        case .togglePostLikeV2(let id, _): "\(id)/like-2"
        case .getMeLikePostListV1: "likes/me"
        case .getMeLikePostListV2: "likes-2/me"
        case .getUserPostList(let userID, _, _, _): "users/\(userID)"
        case .searchHashTagList: "hashTags"
        case .searchFollowFeedList: "feed"
        case .searchGeolocationPostList: "geolocation"
        case .searchPostTitle: "search"
        }
    }
    
    var body: Data? {
        return switch self {
        case .uploadPost(let requestDTO), .updatePost(_, let requestDTO):
            try? Self.encoder.encode(requestDTO)
        case .togglePostLikeV1(_, let like_status):
            try? Self.encoder.encode(["like_status": like_status])
        case .togglePostLikeV2(_, let like_status):
            try? Self.encoder.encode(["like_status": like_status])
        default: nil
        }
    }
    
    var query: [URLQueryItem]? {
        switch self {
        case .getPostList(let next, let limit, let category),
             .getMeLikePostListV1(let next, let limit, let category),
             .getMeLikePostListV2(let next, let limit, let category),
             .searchFollowFeedList(let next, let limit, let category):
            return [URLQueryItem(name: "next", value: next), URLQueryItem(name: "limit", value: limit)]
            + category.map {
                URLQueryItem(name: "category", value: $0)
            }
        case .searchHashTagList(let next, let limit, let category, let hashTag):
           return [URLQueryItem(name: "next", value: next),
                   URLQueryItem(name: "limit", value: limit),
                   URLQueryItem(name: "hashTag", value: hashTag)]
           + category.map {
               URLQueryItem(name: "category", value: $0)
           }
        case .searchGeolocationPostList(let category, let longitude, let latitude, let maxDistance, let order_by, let sort_by):
            return [URLQueryItem(name: "longitude", value: longitude),
                    URLQueryItem(name: "latitude", value: latitude),
                    URLQueryItem(name: "maxDistance", value: maxDistance),
                    URLQueryItem(name: "order_by", value: order_by.rawValue),
                    URLQueryItem(name: "sort_by", value: sort_by.rawValue)]
            + category.map {
                URLQueryItem(name: "category", value: $0)
            }
        case .searchPostTitle(let title, let category):
            return [URLQueryItem(name: "title", value: title)]
            + category.map {
                URLQueryItem(name: "category", value: $0)
            }
        default:
            return nil
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        var components = URLComponents(string: self.baseURL.appendingPathComponent(self.path).absoluteString)!
        components.queryItems = self.query
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
