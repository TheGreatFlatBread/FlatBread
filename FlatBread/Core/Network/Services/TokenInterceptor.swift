//
//  TokenInterceptor.swift
//  FlatBread
//
//  Created by hwan on 11/7/25.
//

import Foundation
import Alamofire

final class TokenInterceptor: RequestInterceptor {
    private let coordinator: TokenRefreshCoordinator
    private let maxCount: Int
    
    private actor RetryState {
        private var retryingRequests: Set<String> = []

        func markAsRetrying(_ id: String) {
            retryingRequests.insert(id)
        }

        func isRetrying(_ id: String) -> Bool {
            return retryingRequests.contains(id)
        }

        func removeRetrying(_ id: String) {
            retryingRequests.remove(id)
        }
    }
    
    private let retryState = RetryState()

    init(coordinator: TokenRefreshCoordinator, maxCount: Int = 3) {
        self.coordinator = coordinator
        self.maxCount = maxCount
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        Task {
            var urlRequest = urlRequest
            let requestID = urlRequest.url?.absoluteString ?? UUID().uuidString

            if await retryState.isRetrying(requestID), urlRequest.headers["Authorization"] != nil {
                let accessToken = await coordinator.getAccessToken()
                urlRequest.headers.remove(name: "Authorization")
                urlRequest.headers.add(HTTPHeader(name: "Authorization", value: accessToken))
                await retryState.removeRetrying(requestID)
                completion(.success(urlRequest))
                return
            }

            if urlRequest.headers["Authorization"] != nil {
                completion(.success(urlRequest))
                return
            }

            let accessToken = await coordinator.getAccessToken()
            if accessToken.isEmpty {
                completion(.failure(NetworkError.apiError(.accessTokenEmpty)))
            } else {
                urlRequest.headers.add(HTTPHeader(name: "Authorization", value: accessToken))
                completion(.success(urlRequest))
            }
        }
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        Task {
            guard request.retryCount < maxCount else {
                completion(.doNotRetryWithError(NetworkError.maxRetryExceeded))
                return
            }
            
            guard let statusCode = request.response?.statusCode,
                  statusCode == 401 || statusCode == 419 else {
                completion(.doNotRetryWithError(NetworkError.fromStatusCode(request.response?.statusCode ?? -1)))
                return
            }

            let failedWithToken = request.request?.headers["Authorization"] ?? ""

            let currentToken = await coordinator.getAccessToken()

            if !failedWithToken.isEmpty && failedWithToken != currentToken {
                let requestID = request.request?.url?.absoluteString ?? UUID().uuidString
                await retryState.markAsRetrying(requestID)
                completion(.retry)
                return
            }

            do {
                _ = try await coordinator.refreshToken()
                let requestID = request.request?.url?.absoluteString ?? UUID().uuidString
                await retryState.markAsRetrying(requestID)
                completion(.retry)
            } catch {
                completion(.doNotRetryWithError(error))
            }
        }
    }
}
