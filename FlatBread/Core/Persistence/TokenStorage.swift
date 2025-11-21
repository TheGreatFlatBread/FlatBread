//
//  TokenStorage.swift
//  FlatBread
//
//  Created by hwan on 11/7/25.
//

import Foundation
import Security

protocol TokenStorage: Sendable {
    func getAccessToken() async -> String?
    func getRefreshToken() async -> String?
    func getAppleUserID() async -> String?
    func saveToken(access: String, refresh: String) async
    func saveAppleUserID(_ userID: String) async
    func clearTokens() async
}

actor DefaultTokenStorage: TokenStorage {
    enum UserDefaultsKey: String {
        case accessToken
        case refreshToken
        case appleUserID
    }

    init() { }

    func getAccessToken() async -> String? {
        UserDefaults.standard.string(forKey: UserDefaultsKey.accessToken.rawValue)
    }

    func getRefreshToken() async -> String? {
        UserDefaults.standard.string(forKey: UserDefaultsKey.refreshToken.rawValue)
    }

    func getAppleUserID() async -> String? {
        UserDefaults.standard.string(forKey: UserDefaultsKey.appleUserID.rawValue)
    }

    func saveToken(access: String, refresh: String) {
        UserDefaults.standard.set(access, forKey: UserDefaultsKey.accessToken.rawValue)
        UserDefaults.standard.set(refresh, forKey: UserDefaultsKey.refreshToken.rawValue)
    }

    func saveAppleUserID(_ userID: String) {
        UserDefaults.standard.set(userID, forKey: UserDefaultsKey.appleUserID.rawValue)
    }

    func clearTokens() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.accessToken.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.refreshToken.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.appleUserID.rawValue)
    }
}
