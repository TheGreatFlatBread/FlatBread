//
//  ShortVideoFeedViewModel.swift
//  FlatBread
//
//  Created by 김민성 on 11/23/25.
//

import Combine
import Foundation


final class ShortVideoFeedViewModel: ObservableObject {
    
    // 현재 스크롤 위치(비디오 ID) 추적
    @Published var currentVideo: ShortVideo?
    @Published var shortVideos: [ShortVideo] = []
    @Published var myProfile: ShortVideoProfile?
    @Published var isLongPressing: Bool = false
    
    // MARK: - Dependencies
    let playerManager: PlayerManager
    let networkService: any AsyncNetworkService
    let prefetcher: any ShortVideoPrefetcher
    private let videoServiceFactory: ShortVideoServiceFactory

    private var isLoading: Bool = false
    private var scrollCursor: String = ""
    
    private var cancellables: Set<AnyCancellable> = []
    
    private let prefetchPrevCount = 3
    private let prefetchNextCount = 4
    private let keepPrevCount = 7
    private let keepNexCount = 7
    
    init(videoServiceFactory: ShortVideoServiceFactory = .shared,
         networkServiceFactory: NetworkServiceFactory = NetworkServiceFactory.shared)
    {
        self.videoServiceFactory = videoServiceFactory
        self.playerManager = videoServiceFactory.makePlayerManager()
        self.networkService = networkServiceFactory.makeNetworkService()
        self.prefetcher = videoServiceFactory.makeShortVideoPrefetcher(on: .memory)
        
        self.getMyProfile()
        
        $currentVideo
            .sink { [weak self] newVideo in
                guard let self, let newVideo else { return }
                handleScrollChange(currentID: newVideo.id)
            }
            .store(in: &cancellables)
    }
    
    private func handleScrollChange(currentID: String) {
        guard let currentIndex = shortVideos.firstIndex(where: { $0.id == currentID }) else { return }
        
        print("스크롤 감지. Index: \(currentIndex)")
        prefetcher.cancelPrefetch(videoID: currentID)
        
        let prefetchStart = max(0, currentIndex - prefetchPrevCount)
        let prefetchEnd = min(shortVideos.count - 1, currentIndex + prefetchNextCount)
        
        for (index, video) in shortVideos.enumerated() {
            if (prefetchStart <= index && index <= prefetchEnd) && (index != currentIndex) {
                prefetcher.startPrefetch(video: video)
            }
        }
        
        let keepStart = max(0, currentIndex - keepPrevCount)
        let keepEnd = min(shortVideos.count - 1, currentIndex + keepNexCount)
        
        for (index, video) in shortVideos.enumerated() {
            if index < keepStart || index > keepEnd {
                prefetcher.cancelAndRemoveCache(videoID: video.id)
            }
        }
    }
    
    func updateShortVideos() async {
        isLoading = true
        let router = PostRouter.searchHashTagList(
            next: scrollCursor,
            limit: "100",
            category: [],
            hashTag: "FBP_shortVideo"
        )
        do {
            let newVideos = try await networkService
                .request(router, responseType: PostListResponseDTO.self).data
                .map { dto in
                    let video = dto.asShortVideoItem
                    video.setPrefetcher(self.prefetcher)
                    return video
                }
            
            await MainActor.run {
                self.shortVideos = newVideos
            }
        } catch {
            print(error.localizedDescription)
        }
        isLoading = false
    }
    
    private func getMyProfile() {
        Task {
            do {
                myProfile = try await networkService.request(
                    UserRouter.getMeProfile,
                    responseType: UserProfileResponseDTO.self
                ).asShortVideoProfile
            } catch {
                print("Failed to load current user profile: \(error)")
            }
        }
    }
    
}
