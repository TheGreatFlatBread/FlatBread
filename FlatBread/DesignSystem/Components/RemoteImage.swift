//
//  RemoteImageView.swift
//  FlatBread
//
//  Created by hwan on 11/14/25.
//

import SwiftUI
import HwanCache

enum ImageSource: Hashable {
    case url(String)
    case uiImage(UIImage)
}

struct RemoteImage<Content: View>: View {
    let source: ImageSource
    let displayMode: ImageDisplayMode
    let cacheStretagy: CacheStrategy
    let content: (Image) -> Content
    let placeholder: AnyView?

    @Environment(\.imageService) var imageService: HWImageService

    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    @State private var loadFailed = false

    init<PlaceholderContent: View>(
        source: ImageSource,
        displayMode: ImageDisplayMode = .original,
        cacheStretagy: CacheStrategy = .both(diskExpiration: 7 * 3600 * 24),
        @ViewBuilder placeholder: () -> PlaceholderContent,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.source = source
        self.displayMode = displayMode
        self.cacheStretagy = cacheStretagy
        self.placeholder = AnyView(placeholder())
        self.content = content
    }

    init(
        source: ImageSource,
        displayMode: ImageDisplayMode = .original,
        cacheStretagy: CacheStrategy = .both(diskExpiration: 7 * 3600 * 24),
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.source = source
        self.displayMode = displayMode
        self.cacheStretagy = cacheStretagy
        self.placeholder = nil
        self.content = content
    }
    
    var body: some View {
        Group {
            if let image = loadedImage {
                content(Image(uiImage: image))
            } else if isLoading {
                ProgressView()
            } else if loadFailed {
                if let placeholder = placeholder {
                    placeholder
                } else {
                    Color.gray.opacity(0.3)
                        .overlay(
                            Image(systemName: "photo.fill")
                                .foregroundColor(.gray)
                        )
                }
            } else {
                Color.clear
                    .onAppear {
                        loadImage()
                    }
            }
        }
        .onChange(of: source) { _, newValue in
            loadImage()
        }
    }
    
    private func loadImage() {
        switch source {
        case .uiImage(let image):
            loadedImage = image

        case .url(let urlString):
            guard !urlString.isEmpty else {
                loadFailed = true
                return
            }

            isLoading = true

            guard let url = URL(string: urlString) else {
                isLoading = false
                loadFailed = true
                return
            }

            Task {
                do {
                    let image = try await imageService.loadImage(
                        from: url,
                        displayMode: displayMode.toHWImageDisplayMode(),
                        cacheStrategy: cacheStretagy.toHWCacheStrategy()
                    )
                    await MainActor.run {
                        loadedImage = image
                        isLoading = false
                    }
                } catch {
                    #if DEBUG
                    print("이미지 로드 실패: \(urlString), 에러: \(error)")
                    #endif
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
    // placeholder 있는 버전
    init<PlaceholderContent: View>(
        url: String,
        displayMode: ImageDisplayMode = .original,
        @ViewBuilder placeholder: @escaping () -> PlaceholderContent,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(source: .url(url), displayMode: displayMode, placeholder: placeholder, content: content)
    }

    // placeholder 없는 버전
    init(
        url: String,
        displayMode: ImageDisplayMode = .original,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(source: .url(url), displayMode: displayMode, content: content)
    }

    // UIImage placeholder 있는 버전
    init<PlaceholderContent: View>(
        uiImage: UIImage,
        displayMode: ImageDisplayMode = .original,
        @ViewBuilder placeholder: @escaping () -> PlaceholderContent,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(source: .uiImage(uiImage), displayMode: displayMode, placeholder: placeholder, content: content)
    }

    // UIImage placeholder 없는 버전
    init(
        uiImage: UIImage,
        displayMode: ImageDisplayMode = .original,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(source: .uiImage(uiImage), displayMode: displayMode, content: content)
    }
}
