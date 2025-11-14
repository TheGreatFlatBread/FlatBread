//
//  CoreNetworkError.swift
//  FlatBread
//
//  Created by hwan on 11/6/25.
//

import Foundation

enum FBAPIError: Error {
    case invalidAccessToken   // 401
    case invalidUserID        // 403
    case expiredAccessToken   // 419
    case invalidApiKey        // 420
    case invalidProductID     // 421
    case execcedApiLimit      // 429
    case invalidApiCall       // 444
    case internalServerError  // 500
    case invalidStatusCode(status: Int, reson: String)
    case failedReissueToken   // 418
    case accessTokenEmpty     // Token 값이 비어있을 경우
    case unknownError
}
 
extension FBAPIError: CustomStringConvertible {
    var description: String {
        return switch self {
        case .invalidAccessToken:
            "인증할 수 없는 액세스 토큰"
        case .invalidUserID:
            "Forbidden"
        case .expiredAccessToken:
            "토큰 만료 됨"
        case .invalidApiKey:
            "api key 유효하지 않음"
        case .invalidProductID:
            "product id 유효하지 않음"
        case .execcedApiLimit:
            "api request execced limit"
        case .invalidApiCall:
            "비정상적인 요청"
        case .internalServerError:
            "internal server Error"
        case .invalidStatusCode(let status, let reason):
            "invalidStatusCode - statusCode: \(status), reason: \(reason)"
        case .failedReissueToken:
            "토큰 재발행 실패 - 로그인 필요"
        case .accessTokenEmpty:
            "accessToken Empty 로그인 재발행 필요"
        case .unknownError:
            "unknownError occur"
        }
    }
}
