//
//  RemoteImageView.swift
//  FlatBread
//
//  Created by hwan on 11/14/25.
//

import SwiftUI
import Kingfisher

enum ImageSource {
    case url(String)
    case uiImage(UIImage)
}

enum ImageDisplayMode {
    case thumbnail(CGSize)
    case original
}

struct RemoteImage<Content: View>: View {
    let source: ImageSource
    let displayMode: ImageDisplayMode
    let content: (Image) -> Content

    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    @State private var loadFailed = false

    init(
        source: ImageSource,
        displayMode: ImageDisplayMode = .original,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.source = source
        self.displayMode = displayMode
        self.content = content
    }
    
    var body: some View {
        Group {
            if let image = loadedImage {
                content(Image(uiImage: image))
            } else if isLoading {
                ProgressView()
            } else if loadFailed {
                Color.gray.opacity(0.3)
                    .overlay(
                        Image(systemName: "photo.fill")
                            .foregroundColor(.gray)
                    )
            } else {
                Color.clear
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        switch source {
        case .uiImage(let image):
            loadedImage = image
            
        case .url(let urlString):
            isLoading = true
            
            guard let url = URL(string: urlString) else {
                isLoading = false
                return
            }

            Task {
                do {
                    if url.isFileURL {
                        let options: KingfisherOptionsInfo
                        switch displayMode {
                            case .thumbnail(let size):
                                options = [
                                    .processor(DownsamplingImageProcessor(size: size)),
                                    .scaleFactor(UIScreen.main.scale),
                                    .cacheMemoryOnly,
                                    .backgroundDecode
                                ]
                            case .original:
                                options = [
                                    .memoryCacheExpiration(.expired),
                                    .diskCacheExpiration(.expired),
                                    .backgroundDecode
                                ]
                        }
                        let retrieveImage = try await KingfisherManager.shared.retrieveImage(
                            with: .provider(LocalFileImageDataProvider(fileURL: url)),
                            options: options
                        )
                        await MainActor.run {
                            loadedImage = retrieveImage.image
                            isLoading = false
                        }
                    } else {
                        #if DEBUG
                        print("🔍 RemoteImage 로드 시도: \(url.absoluteString)")
                        #endif
                        
                        var image: UIImage
                        
                        let result = try await ImageCache.default.retrieveImage(forKey: urlString)
                        
                        switch result {
                        case .disk(let _image), .memory(let _image):
                            image = _image
                        default:
                            let options: KingfisherOptionsInfo
                            switch displayMode {
                            case .thumbnail(let size):
                                options = [
                                    .processor(DownsamplingImageProcessor(size: size)),
                                    .scaleFactor(UIScreen.main.scale),
                                    .cacheOriginalImage,
                                    .diskCacheExpiration(.days(7)),
                                    .backgroundDecode,
                                    .transition(.fade(0.2))
                                ]
                            case .original:
                                options = [
                                    .diskCacheExpiration(.days(7)),
                                    .cacheOriginalImage,
                                    .backgroundDecode,
                                    .transition(.fade(0.2))
                                ]
                            }
                            let retrieveImage = try await KingfisherManager.shared.retrieveImage(
                                with: .network(url),
                                options: options
                            )
                            image = retrieveImage.image
                        }
                        await MainActor.run {
                            loadedImage = image
                            isLoading = false
                        }
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        loadFailed = true
                    }
                }
            }
        }
    }
}

extension RemoteImage {
    init(url: String, displayMode: ImageDisplayMode = .original, @ViewBuilder content: @escaping (Image) -> Content) {
        self.init(source: .url(url), displayMode: displayMode, content: content)
    }

    init(uiImage: UIImage, displayMode: ImageDisplayMode = .original, @ViewBuilder content: @escaping (Image) -> Content) {
        self.init(source: .uiImage(uiImage), displayMode: displayMode, content: content)
    }
}
