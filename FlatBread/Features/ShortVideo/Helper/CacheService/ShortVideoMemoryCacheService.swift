//
//  ShortVideoMemoryCacheService.swift
//  FlatBread
//
//  Created by 김민성 on 11/24/25.
//

import Foundation

final class ShortVideoMemoryCacheService: ShortVideoCacheService {
    static let shared = ShortVideoMemoryCacheService()
    
    private let cacheLock = NSLock()
    private var cacheList: [String: ShortVideoPreloadCache] = [:]
    
    func saveCache(for id: String, cache: ShortVideoPreloadCache) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        cacheList[id] = cache
    }
    
    func getCache(for id: String) -> ShortVideoPreloadCache? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return cacheList[id]
    }
    
    func removeCache(for id: String) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        cacheList.removeValue(forKey: id)
    }
    
    func clearAll() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        cacheList.removeAll()
    }
    
    func isCached(for id: String) -> Bool {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return cacheList[id] != nil
    }
}
