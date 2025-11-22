//
//  TokenRefreshCoordinator.swift
//  FlatBread
//
//  Created by hwan on 11/7/25.
//

import Foundation
import Alamofire

actor TokenRefreshCoordinator {
    private var isRefreshing = false
    private var waitingContinuations: [CheckedContinuation<String, Error>] = []

    private let tokenStorage: TokenStorage
    private let session: Session

    init(tokenStorage: TokenStorage, session: Session = .default) {
        self.tokenStorage = tokenStorage
        self.session = session
    }

    func refreshToken() async throws -> String {
        if isRefreshing {
            return try await withCheckedThrowingContinuation() { continuation in
                waitingContinuations.append(continuation)
            }
        }
        isRefreshing = true
        do {
            let token = try await performRefresh()
            let waiters = waitingContinuations
            waitingContinuations.removeAll()
            isRefreshing = false
            for continuation in waiters {
                continuation.resume(returning: token)
            }
            return token
        } catch {
            let waiters = waitingContinuations
            waitingContinuations.removeAll()
            isRefreshing = false
            for continuation in waiters {
                continuation.resume(throwing: error)
            }
            throw error
        }
    }

    nonisolated
    private func performRefresh() async throws -> String {
        do {
            async let accessToken: String? = await tokenStorage.getAccessToken()
            async let refreshToken: String? = await tokenStorage.getRefreshToken()
            
            let (access, refreh) = await (accessToken, refreshToken)
            
            guard let access, let refreh else {
                throw NetworkError.apiError(.accessTokenEmpty)
            }
            
            let router = await RefreshRouter(accessToken: access, refreshToken: refreh)
            let request = session.request(router)
            let response = try await request
                .validate(statusCode: 200..<300)
                .serializingDecodable(RefreshTokenResponseDTO.self)
                .value
            
            if let accessToken = response.accessToken,
                let refreshToken = response.refreshToken
            {
                await tokenStorage.saveToken(access: accessToken, refresh: refreshToken)
                return accessToken
            } else {
                throw NetworkError.apiError(.failedReissueToken)
            }
        } catch let afError as AFError {
            throw NetworkError.from(afError)
        } catch {
            throw NetworkError.apiError(.failedReissueToken)
        }
    }

    nonisolated func getAccessToken() async -> String {
        await tokenStorage.getAccessToken() ?? ""
    }

    nonisolated func saveTokens(access: String, refresh: String) async {
        await tokenStorage.saveToken(access: access, refresh: refresh)
    }

    nonisolated func clearTokens() async {
        await tokenStorage.clearTokens()
    }
}
