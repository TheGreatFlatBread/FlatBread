//
//  APIHeader.swift
//  FlatBread
//
//  Created by hwan on 11/5/25.
//

import Foundation
import Alamofire

enum APIHeader {
    case apiKey
    case applicationJSON
    case multipartForm
    case productID
}

extension APIHeader {
    var httpHeader: HTTPHeader {
        switch self {
        case .apiKey:
            return HTTPHeader(name: "SeSACKey", value: APIConfig.apikey)

        case .applicationJSON:
            return HTTPHeader(name: "Content-Type", value: "application/json")

        case .multipartForm:
            return HTTPHeader(name: "Content-Type", value: "multipart/form-data")

        case .productID:
            return HTTPHeader(name: "ProductId", value: APIConfig.productID)
        }
    }
}
