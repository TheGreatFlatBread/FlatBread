//
//  DefaultImageService.swift
//  FlatBread
//
//  Created by hwan on 11/19/25.
//

import UIKit
import HwanCache

final class ImageDownloader: HWImageDownloader {
    private let networkService: AsyncNetworkService
    
    init(networkService: AsyncNetworkService = NetworkServiceFactory.shared.makeNetworkService()) {
        self.networkService = networkService
    }

    func downloadImage(from urlString: String) async throws -> Data {
        let router = ImageDownloadRouter.downloadImage(path: urlString)
        let fileURL = try await networkService.download(router)
        let data = try Data(contentsOf: fileURL)
        try? FileManager.default.removeItem(at: fileURL)
        return data
    }
    
    func downloadImage(from urlRequest: URLRequest) async throws -> Data {
        fatalError()
    }
}
