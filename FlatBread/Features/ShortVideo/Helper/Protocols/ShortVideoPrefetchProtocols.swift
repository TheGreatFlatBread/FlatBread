//
//  ShortVideoPrefetchProtocols.swift
//  FlatBread
//
//  Created by 김민성 on 11/25/25.
//

import Foundation

/// 캐시된 비디오 데이터와 메타데이터를 묶은 모델
struct ShortVideoPrefetchCache {
    let videoID: String
    let totalLength: Int64
    let contentType: String
    let data: Data
}

/// 캐시 저장소(Memory vs Disk)가 구현해야 할 프로토콜
protocol ShortVideoCacheService {
    func saveCache(for id: String, cache: ShortVideoPrefetchCache)
    func getCache(for id: String) -> ShortVideoPrefetchCache?
    func removeCache(for id: String)
    func clearAll()
    func isCached(for id: String) -> Bool
}

/// Prefetcher가 구현해야 할 프로토콜
protocol ShortVideoPrefetcher: AnyObject {
    func updatePrefetchWindow(around currentIndex: Int, in fullList: [ShortVideo])
    func getPrefetchData(videoID: String) -> ShortVideoPrefetchCache?
    func getCachedSize(videoID: String) -> Int64
}
