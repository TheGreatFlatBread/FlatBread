//
//  ChatRouter.swift
//  FlatBread
//
//  Created by hwan on 11/14/25.
//

import Foundation
import Alamofire

enum ChatRouter: APIRouter {
    static let encoder = JSONEncoder()

    case fetchChatRoomList
    case makeChatRoom(opponent_id: String)
    case fetchChatMessgeList(roomID: String, cursorDate: String)
    case sendMessage(roomID: String, content: String, files: [String])

    var baseURL: URL {
        guard let url = URL(string: APIConfig.baseURL + "/chats/") else {
            assert(false, "is not valid Chat URL")
        }
        return url
    }

    var method: HTTPMethod {
        switch self {
        case .makeChatRoom, .sendMessage:
            return .post
        case .fetchChatMessgeList, .fetchChatRoomList:
            return .get
        }
    }

    var headers: HTTPHeaders {
        let headerTypes: [APIHeader] = [.applicationJSON, .apiKey, .productID]
        return HTTPHeaders(headerTypes.map(\.httpHeader))
    }

    var path: String {
        switch self {
        case .fetchChatMessgeList(let roomID, _):
            return "\(roomID)"
        case .sendMessage(let roomID, _, _):
            return "\(roomID)"
        case .fetchChatRoomList, .makeChatRoom:
            return ""
        }
    }
    
    var query: [URLQueryItem]? {
        switch self {
        case .fetchChatMessgeList(let roomID, let cursorDate):
            [URLQueryItem(name: "room_id", value: roomID),
            URLQueryItem(name: "cursor_date", value: cursorDate)]
        default:
            nil
        }
    }

    var body: Data? {
        switch self {
        case .makeChatRoom(let opponentID):
            return try? Self.encoder.encode(["opponent_id": opponentID])
        case .sendMessage(_, let content, let files):
            return try? Self.encoder.encode(ChatSendRequestDTO(content: content, files: files))
        default:
            return nil
        }
    }

    func asURLRequest() throws -> URLRequest {
        var components = URLComponents(string: self.baseURL.appendingPathComponent(self.path).absoluteString)!
        if let query {
            components.queryItems = query
        }
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.method = self.method
        request.headers = self.headers
        if let body {
            request.httpBody = body
        }
        return request
    }
}
