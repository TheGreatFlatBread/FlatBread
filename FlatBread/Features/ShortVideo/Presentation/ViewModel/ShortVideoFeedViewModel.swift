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
    
    private let playerManager = PlayerManager.shared
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    private var isLoading: Bool = false
    private var scrollCursor: String = ""
    
    private let preloader: any ShortVideoPreloader
    private var cancellables: Set<AnyCancellable> = []
    
    private let preloadPrevCount = 3
    private let preloadNextCount = 4
    private let keepPrevCount = 7
    private let keepNexCount = 7
    
    init(preloader: ShortVideoPreloader = ShortVideoMemoryPreloader.shared) {
        self.preloader = preloader
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
        preloader.cancelPreload(videoID: currentID)
        
        let preloadStart = max(0, currentIndex - preloadPrevCount)
        let preloadEnd = min(shortVideos.count - 1, currentIndex + preloadNextCount)
        
        for (index, video) in shortVideos.enumerated() {
            if (preloadStart <= index && index <= preloadEnd) && (index != currentIndex) {
                preloader.startPreload(video: video)
            }
        }
        
        let keepStart = max(0, currentIndex - keepPrevCount)
        let keepEnd = min(shortVideos.count - 1, currentIndex + keepNexCount)
        
        for (index, video) in shortVideos.enumerated() {
            if index < keepStart || index > keepEnd {
                preloader.cancelAndRemoveCache(videoID: video.id)
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
                    video.setPreloader(self.preloader)
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
