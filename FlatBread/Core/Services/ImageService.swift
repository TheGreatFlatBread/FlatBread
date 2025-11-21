//
//  ImageService.swift
//  FlatBread
//
//  Created by hwan on 11/19/25.
//

import UIKit
import Kingfisher
import Alamofire

protocol ImageService {
    func loadImage(from url: URL, displayMode: ImageDisplayMode) async throws -> UIImage
}

final class DefaultImageService: ImageService {
    static let shared = DefaultImageService(
        networkService: NetworkServiceFactory.shared.makeNetworkService()
    )

    private let networkService: AsyncNetworkService

    init(networkService: AsyncNetworkService) {
        self.networkService = networkService
    }

    func loadImage(from url: URL, displayMode: ImageDisplayMode) async throws -> UIImage {
        let urlString = url.absoluteString
        if url.isFileURL {
            let options = makeFileURLOptions(displayMode: displayMode)
            let result = try await KingfisherManager.shared.retrieveImage(
                with: .provider(LocalFileImageDataProvider(fileURL: url)),
                options: options
            )
            return result.image
        }
        
        let cacheResult = try await ImageCache.default.retrieveImage(forKey: urlString)

        switch cacheResult {
        case .disk(let image), .memory(let image):
            return image

        default:
            let imageData = try await downloadImageData(from: urlString)
            let provider = RawImageDataProvider(data: imageData, cacheKey: urlString)
            let options = makeNetworkURLOptions(displayMode: displayMode)
            let result = try await KingfisherManager.shared.retrieveImage(
                with: .provider(provider),
                options: options
            )

            return result.image
        }
    }

    private func downloadImageData(from urlString: String) async throws -> Data {
        let router = ImageDownloadRouter.downloadImage(path: urlString)
        let fileURL = try await networkService.download(router)
        let data = try Data(contentsOf: fileURL)
        try? FileManager.default.removeItem(at: fileURL)
        return data
    }
    
    private func makeFileURLOptions(displayMode: ImageDisplayMode) -> KingfisherOptionsInfo {
        switch displayMode {
        case .thumbnail(let size):
            return [
                .processor(DownsamplingImageProcessor(size: size)),
                .scaleFactor(UIScreen.main.scale),
                .cacheMemoryOnly,
                .backgroundDecode,
                .transition(.fade(0.2))
            ]
        case .original:
            return [
                .memoryCacheExpiration(.expired),
                .diskCacheExpiration(.expired),
                .backgroundDecode,
                .transition(.fade(0.2))
            ]
        }
    }

    private func makeNetworkURLOptions(displayMode: ImageDisplayMode) -> KingfisherOptionsInfo {
        switch displayMode {
        case .thumbnail(let size):
            return [
                .processor(DownsamplingImageProcessor(size: size)),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage,
                .diskCacheExpiration(.days(7)),
                .backgroundDecode,
                .transition(.fade(0.2))
            ]
        case .original:
            return [
                .diskCacheExpiration(.days(7)),
                .cacheOriginalImage,
                .backgroundDecode,
                .transition(.fade(0.2))
            ]
        }
    }
}

enum ImageDownloadRouter: DownloadAPIRouter {
    case downloadImage(path: String)

    var baseURL: URL {
        URL(string: APIConfig.baseURL)!
    }

    var method: HTTPMethod {
        .get
    }

    var path: String {
        switch self {
        case .downloadImage(let imagePath):
            return imagePath.hasPrefix("/") ? String(imagePath.dropFirst()) : imagePath
        }
    }

    var headers: HTTPHeaders {
        let headerTypes: [APIHeader] = [.apiKey, .productID]
        return HTTPHeaders(headerTypes.map(\.httpHeader))
    }

    var body: Data? {
        nil
    }

    var query: [URLQueryItem]? {
        nil
    }

    var destination: DownloadRequest.Destination {
        let destination: DownloadRequest.Destination = { _, _ in
            let documentsURL = FileManager.default.temporaryDirectory
            let fileURL = documentsURL.appendingPathComponent(UUID().uuidString)
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        return destination
    }

    func asURLRequest() throws -> URLRequest {
        var components = URLComponents(string: baseURL.appendingPathComponent(path).absoluteString)!
        components.queryItems = query
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.method = method
        request.headers = headers
        request.httpBody = body
        return request
    }
}
