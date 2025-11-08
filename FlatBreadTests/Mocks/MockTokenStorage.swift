//
//  MockTokenStorage.swift
//  FlatBreadTests
//
//  Created by hwan on 11/7/25.
//

import Foundation
@testable import FlatBread

actor MockTokenStorage: TokenStorage {
    private var accessToken: String
    private var refreshToken: String
    
    private(set) var getAccessTokenCallCount = 0
    private(set) var getRefreshTokenCallCount = 0
    private(set) var saveTokenCallCount = 0

    init(accessToken: String = "mock-access-token", refreshToken: String = "mock-refresh-token") {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func getAccessToken() async -> String {
        getAccessTokenCallCount += 1
        return accessToken
    }

    func getRefreshToken() async -> String {
        getRefreshTokenCallCount += 1
        return refreshToken
    }

    func saveToken(access: String, refresh: String) async {
        saveTokenCallCount += 1
        self.accessToken = access
        self.refreshToken = refresh
    }

    func clearTokens() async {
        self.accessToken = ""
        self.refreshToken = ""
    }

    func reset() {
        getAccessTokenCallCount = 0
        getRefreshTokenCallCount = 0
        saveTokenCallCount = 0
    }
}
