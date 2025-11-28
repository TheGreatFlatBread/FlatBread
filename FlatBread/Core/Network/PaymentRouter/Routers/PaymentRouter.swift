//
//  PaymentRouter.swift
//  FlatBread
//
//  Created by andev on 11/25/25.
//

import Foundation
import Alamofire

enum PaymentRouter: APIRouter {
    static let encoder = JSONEncoder()

    case validatePayment(request: PaymentValidationRequestDTO)
    case myPaymentList(request: PaymentListResponseDTO)

    var baseURL: URL {
        if let url = URL(string: APIConfig.baseURL + "/payments/") {
            return url
        } else {
            assert(false, "is not valid Payment URL")
        }
    }

    var method: HTTPMethod {
        switch self {
        case .validatePayment:
            return .post
        case .myPaymentList:
            return .get
        }
    }

    var headers: HTTPHeaders {
        // Align with PostRouter default headers
        let headerTypes: [APIHeader] = [.applicationJSON, .apiKey, .productID]
        return HTTPHeaders(headerTypes.map(\.httpHeader))
    }

    var path: String {
        switch self {
        case .validatePayment:
            return "validation"
        case .myPaymentList:
            return "me"
        }
    }

    var body: Data? {
        switch self {
        case .validatePayment(let requestDTO):
            return try? Self.encoder.encode(requestDTO)
        case .myPaymentList:
            return nil
        }
    }

    var query: [URLQueryItem]? { nil }

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
