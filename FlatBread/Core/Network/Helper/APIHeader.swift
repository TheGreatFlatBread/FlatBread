//
//  APIHeader.swift
//  FlatBread
//
//  Created by hwan on 11/5/25.
//

import Foundation
import Alamofire

enum APIHeader {
    case accessToken
    case apiKey
    case contentType
    case applicationJSON
    case multipartForm
    case productID
}

extension APIHeader {
    var httpHeader: HTTPHeader {
        switch self {
        case .accessToken:
            return HTTPHeader(name: "Authorization", value: "accessToken")
        
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
