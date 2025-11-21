//
//  UserCache.swift
//  FlatBread
//
//  Created by hwan on 11/19/25.
//

import Foundation

actor UserCache {
    static let shared = UserCache()

    private var cache: [String: CachedUser] = [:]
    private let cacheExpiration: TimeInterval = 300

    private struct CachedUser {
        let user: UserProfileResponseDTO
        let cachedAt: Date

        var isExpired: Bool {
            Date.now.timeIntervalSince(cachedAt) > 300
        }
    }

    private init() {}

    func get(_ userId: String) -> UserProfileResponseDTO? {
        guard let cached = cache[userId], !cached.isExpired else {
            cache.removeValue(forKey: userId)
            return nil
        }
        return cached.user
    }

    func set(_ userId: String, user: UserProfileResponseDTO) {
        cache[userId] = CachedUser(user: user, cachedAt: Date())
    }

    func clear() {
        cache.removeAll()
    }

    func clearExpired() {
        cache = cache.filter { !$0.value.isExpired }
    }
}
