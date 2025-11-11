//
//  NetworkService.swift
//  FlatBread
//
//  Created by hwan on 11/4/25.
//

import Foundation
import Alamofire

enum UserRouter: APIRouter {
    
    static let encoder = JSONEncoder()
    
    case validation(email: String)
    case signUp(request: UserSignUpRequestDTO)
    case login(email: String, password: String)
    case loginKakao(oauthToken: String)
    case loginApple(idToken: String)
    case signOut
    case searchUser(nick: String)
    case getMeProfile
    case getOtherUserProfile(userID: String)
    
    var baseURL: URL {
        if let url = URL(string: APIConfig.baseURL + "/users/") {
            return url
        } else {
            assert(false, "is not valid User URL")
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .validation, .signUp, .login, .loginKakao, .loginApple:
            return .post
        case .signOut, .searchUser, .getMeProfile, .getOtherUserProfile:
            return .get
        }
    }
    
    var headers: HTTPHeaders {
        switch self {
        case .validation, .signUp, .login, .loginKakao, .loginApple:
            let headerTypes: [APIHeader] = [.applicationJSON, .productID, .apiKey]
            return HTTPHeaders(headerTypes.map(\.httpHeader))

        case .signOut, .searchUser, .getMeProfile, .getOtherUserProfile:
            let headerTypes: [APIHeader] = [.applicationJSON, .apiKey, .productID]
            return HTTPHeaders(headerTypes.map(\.httpHeader))
        }
    }
    
    var path: String {
        return switch self {
        case .validation: "validation/email"
        case .signUp: "join"
        case .login: "login"
        case .loginKakao: "login/kakao"
        case .loginApple: "login/apple"
        case .signOut: "withdraw"
        case .searchUser: "search"
        case .getMeProfile: "me/profile"
        case .getOtherUserProfile(let userID): "\(userID)/profile"
        }
    }
    
    var body: Data? {
        return switch self {
        case .validation(let email):
            try? Self.encoder.encode(["email": email])
        case .signUp(let request):
            try? Self.encoder.encode(request)
        case .login(let email, let password):
            try? Self.encoder.encode(["email": email, "password": password])
        case .loginKakao(let oauthToken):
            try? Self.encoder.encode(["oauthToken": oauthToken])
        case .loginApple(let idToken):
            try? Self.encoder.encode(["idToken": idToken])
        case .signOut: nil
        case .searchUser: nil
        case .getMeProfile: nil
        case .getOtherUserProfile: nil
        }
    }
    
    var query: [URLQueryItem]? {
        switch self {
        case .searchUser(let nick):
            return [URLQueryItem(name: "nick", value: nick)]
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
