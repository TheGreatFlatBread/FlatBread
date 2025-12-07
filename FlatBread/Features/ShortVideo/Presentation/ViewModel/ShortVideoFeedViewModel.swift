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
        prefetcher.updatePrefetchWindow(around: currentIndex, in: shortVideos)
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
