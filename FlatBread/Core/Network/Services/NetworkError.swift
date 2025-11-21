//
//  NetworkError.swift
//  FlatBread
//
//  Created by hwan on 11/6/25.
//

import Foundation
import Alamofire

enum NetworkError: LocalizedError, Equatable {
    
    case apiError(FBAPIError)
    case networkFailure
    case timeout
    case noInternetConnection
    case maxRetryExceeded
    case uploadFailed
    case decodingFailed
    case invalidResponse
    case invalidURL
    case unknown(Error)
    
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.apiError(let a), .apiError(let b)):
            return a == b
        case (.networkFailure, .networkFailure),
             (.timeout, .timeout),
             (.noInternetConnection, .noInternetConnection),
             (.maxRetryExceeded, .maxRetryExceeded),
             (.uploadFailed, .uploadFailed),
             (.decodingFailed, .decodingFailed),
             (.invalidResponse, .invalidResponse),
             (.invalidURL, .invalidURL):
            return true
        case (.unknown(let e1), .unknown(let e2)):
            return e1.localizedDescription == e2.localizedDescription
        default:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .networkFailure:
            return "네트워크 연결에 실패했습니다"
        case .timeout:
            return "요청 시간이 초과되었습니다"
        case .noInternetConnection:
            return "인터넷 연결을 확인해주세요"
        case .apiError(let fbError):
            return fbError.description
        case .uploadFailed:
            return "업로드에 실패했습니다"
        case .decodingFailed:
            return "데이터 처리 중 오류가 발생했습니다"
        case .invalidResponse:
            return "잘못된 응답입니다"
        case .invalidURL:
            return "잘못된 URL입니다"
        case .maxRetryExceeded:
            return "재요청 횟수 초과되었습니다."
        case .unknown(let error):
            return "알 수 없는 오류: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkFailure, .timeout, .noInternetConnection:
            return "네트워크 연결 상태를 확인하고 다시 시도해주세요"
        case .apiError(let fbError):
            switch fbError {
            case .invalidAccessToken, .expiredAccessToken:
                return "다시 로그인해주세요"
            case .invalidUserID:
                return "관리자에게 문의하세요"
            case .invalidApiKey, .invalidProductID:
                return "앱을 재설치하거나 관리자에게 문의하세요"
            case .execcedApiLimit:
                return "잠시 후 다시 시도해주세요"
            case .invalidApiCall:
                return "올바른 요청인지 확인해주세요"
            case .internalServerError:
                return "잠시 후 다시 시도해주세요"
            default:
                return "다시 시도해주세요"
            }
        default:
            return "다시 시도해주세요"
        }
    }
}

extension NetworkError {
    static func from(_ afError: AFError) -> NetworkError {
        switch afError {
        case .sessionTaskFailed(let error as NSError):
            switch error.code {
            case NSURLErrorNotConnectedToInternet:
                return .noInternetConnection
            case NSURLErrorTimedOut:
                return .timeout
            case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                return .networkFailure
            default:
                return .unknown(afError)
            }

        case .responseValidationFailed(let reason):
            switch reason {
            case .unacceptableStatusCode(let code):
                return Self.fromStatusCode(code)
            case .dataFileNil, .dataFileReadFailed:
                return .uploadFailed
            default:
                return .invalidResponse
            }

        case .responseSerializationFailed:
            return .decodingFailed

        default:
            return .unknown(afError)
        }
    }

    static func fromStatusCode(_ code: Int) -> NetworkError {
        switch code {
        case 401:
            return .apiError(.invalidAccessToken)
        case 403:
            return .apiError(.invalidUserID)
        case 418:
            return .apiError(.failedReissueToken)
        case 419:
            return .apiError(.expiredAccessToken)
        case 420:
            return .apiError(.invalidApiKey)
        case 421:
            return .apiError(.invalidProductID)
        case 429:
            return .apiError(.execcedApiLimit)
        case 444:
            return .apiError(.invalidApiCall)
        case 500:
            return .apiError(.internalServerError)
        case 500...599:
            return .apiError(.internalServerError)
        default:
            return .apiError(.invalidStatusCode(status: code, reson: "알 수 없는 상태 코드"))
        }
    }
}
