//
//  ImageServiceKey.swift
//  FlatBread
//
//  Created by hwan on 11/25/25.
//

import SwiftUI
import HwanCache

struct ImageServiceKey: EnvironmentKey {
    static let defaultValue: HWImageService = HWDefaultImageService(
        downloader: ImageDownloader(),
        cacheManager: HWCacheManager.shared
    )
}

extension EnvironmentValues {
    var imageService: HWImageService {
        get { self[ImageServiceKey.self] }
        set { self[ImageServiceKey.self] = newValue }
    }
}
