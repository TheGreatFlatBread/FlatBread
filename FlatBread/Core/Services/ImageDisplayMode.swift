//
//  ImageDisplayMode.swift
//  FlatBread
//
//  Created by hwan on 11/25/25.
//

import Foundation
import HwanCache

enum ImageDisplayMode: Sendable {
    case original
    case thumbnail(_ size: CGSize)
}

extension ImageDisplayMode {
    func toHWImageDisplayMode() -> HWImageDisplayMode {
        switch self {
        case .original:
            return .original
        case .thumbnail(let size):
            return .thumbnail(size)
        }
    }
}

enum CacheStrategy: Sendable {
    case memoryOnly
    case diskOnly(expiration: TimeInterval)
    case both(diskExpiration: TimeInterval)
}

extension CacheStrategy {
    func toHWCacheStrategy() -> HWCacheStrategy {
        switch self {
        case .memoryOnly:
            return .memoryOnly
        case .diskOnly(let expiration):
            return .diskOnly(expiration: expiration)
        case .both(let diskExpiration):
            return .both(diskExpiration: diskExpiration)
        }
    }
}
