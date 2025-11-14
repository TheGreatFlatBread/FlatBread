//
//  TokenStorage.swift
//  FlatBread
//
//  Created by hwan on 11/7/25.
//

import Foundation
import Security

protocol TokenStorage: Sendable {
    func getAccessToken() async -> String
    func getRefreshToken() async -> String
    func saveToken(access: String, refresh: String) async
    func clearTokens() async
}

actor DefaultTokenStorage: TokenStorage {
    enum UserDefaultsKey: String {
        case accessToken
        case refreshToken
    }
    
    init() { }

    func getAccessToken() async -> String {
        UserDefaults.standard.value(forKey: UserDefaultsKey.accessToken.rawValue) as! String
    }

    func getRefreshToken() async -> String {
        UserDefaults.standard.value(forKey: UserDefaultsKey.refreshToken.rawValue) as! String
    }

    func saveToken(access: String, refresh: String) {
        UserDefaults.standard.set(access, forKey: UserDefaultsKey.accessToken.rawValue)
        UserDefaults.standard.set(refresh, forKey: UserDefaultsKey.refreshToken.rawValue)
    }

    func clearTokens() {
        UserDefaults.standard.set("", forKey: UserDefaultsKey.accessToken.rawValue)
        UserDefaults.standard.set("", forKey: UserDefaultsKey.refreshToken.rawValue)
    }
}
