//
//  ShortVideoServiceFactory.swift
//  FlatBread
//
//  Created by Gemini on 12/3/25.
//

import Foundation

final class ShortVideoServiceFactory {
    
    enum CacheStorage {
        /// 숏폼 비디오 캐싱을 메모리에 저장
        case memory
        /// 숏폼 비디오 캐싱을 FileManager에 저장
        case disk
    }
    
    static let shared = ShortVideoServiceFactory()
    private static let playerManager = PlayerManager.shared
    
    private init() {}
    
    private static let shortVideoMemoryCacheService = ShortVideoMemoryCacheService.shared
    private static let shortVideoDiskCacheService = ShortVideoDiskCacheService.shared
    
    func makePlayerManager() -> PlayerManager {
        return Self.playerManager
    }
    
    func makeShortVideoPrefetcher(on storage: CacheStorage) -> ShortVideoPrefetcher {
        let cacheService = makeShortVideoCacheService(on: storage)
        let networkService = NetworkServiceFactory.shared.makeNetworkService()
        return ShortVideoPrefetcherImpl(cacheService: cacheService, networkService: networkService)
    }
    
    private func makeShortVideoCacheService(on storage: CacheStorage) -> ShortVideoCacheService {
        switch storage {
        case .memory:
            return Self.shortVideoMemoryCacheService
        case .disk:
            return Self.shortVideoDiskCacheService
        }
    }
    
}
