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

    init(coordinator: TokenRefreshCoordinator, maxCount: Int = 3) {
        self.coordinator = coordinator
        self.maxCount = maxCount
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        Task {
            var urlRequest = urlRequest
            if urlRequest.headers["Authorization"] == nil {
                let accessToken = await coordinator.getAccessToken()
                if accessToken.isEmpty {
                    completion(.failure(NetworkError.apiError(.accessTokenEmpty)))
                } else {
                    urlRequest.headers.add(HTTPHeader(name: "Authorization", value: accessToken))
                    completion(.success(urlRequest))
                }
            } else {
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
            do {
                _ = try await coordinator.refreshToken()
                completion(.retry)
            } catch {
                completion(.doNotRetryWithError(error))
            }
        }
    }
}
