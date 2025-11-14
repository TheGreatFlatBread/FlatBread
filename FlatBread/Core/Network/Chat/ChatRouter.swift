//
//  ChatRouter.swift
//  FlatBread
//
//  Created by hwan on 11/14/25.
//

import Foundation
import Alamofire

enum ChatRouter: APIRouter {
    case sendMessage(roomID: String, content: String, files: [String])
    case getMessages(roomID: String, cursorDate: String?)
    case getChatRooms

    var baseURL: URL {
        guard let url = URL(string: APIConfig.baseURL + "/chats/") else {
            assert(false, "is not valid Chat URL")
        }
        return url
    }

    var method: HTTPMethod {
        switch self {
        case .sendMessage:
            return .post
        case .getMessages, .getChatRooms:
            return .get
        }
    }

    var headers: HTTPHeaders {
        let headerTypes: [APIHeader] = [.applicationJSON, .apiKey, .productID]
        return HTTPHeaders(headerTypes.map(\.httpHeader))
    }

    var path: String {
        switch self {
        case .sendMessage(let roomID, _, _):
            return "\(roomID)"
        case .getMessages(let roomID, _):
            return "\(roomID)"
        case .getChatRooms:
            return "my"
        }
    }

    var parameters: Parameters? {
        switch self {
        case .sendMessage(_, let content, let files):
            var params: [String: Any] = [:]
            if !content.isEmpty {
                params["content"] = content
            }
            if !files.isEmpty {
                params["files"] = files
            }
            return params
        case .getMessages(_, let cursorDate):
            if let cursorDate = cursorDate {
                return ["cursor_date": cursorDate]
            }
            return nil
        case .getChatRooms:
            return nil
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .sendMessage:
            return JSONEncoding.default
        case .getMessages, .getChatRooms:
            return URLEncoding.queryString
        }
    }

    func asURLRequest() throws -> URLRequest {
        guard let url = URL(string: self.baseURL.appendingPathComponent(self.path).absoluteString) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.method = self.method
        request.headers = self.headers
        return try self.encoding.encode(request, with: self.parameters)
    }
}
