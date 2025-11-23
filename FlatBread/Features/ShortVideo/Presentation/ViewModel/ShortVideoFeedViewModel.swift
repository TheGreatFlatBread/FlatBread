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
    @Published var currentVideoID: String?
    @Published var shortVideos: [ShortVideo] = []
    
    private let playerManager = PlayerManager.shared
    let shortVideosResponseDummy: [PostResponseDTO] = PostResponseDTO.shortVideosDummy
    
    private let preloader = ShortVideoPreloader.shared
    private var cancellables: Set<AnyCancellable> = []
    
    private let preloadPrevCount = 2
    private let preloadNextCount = 3
    private let keepPrevCount = 5
    private let keepNexCount = 10
    
    init() {
        $currentVideoID
            .sink { [weak self] newID in
                guard let self, let newID else { return }
                handleScrollChange(currentID: newID)
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
            } else {
                let isPreloadTarget = (index > currentIndex && index <= preloadEnd)
                if !isPreloadTarget {
                    preloader.cancelPreload(videoID: video.id)
                }
            }
        }
    }
    
}
