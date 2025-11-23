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
    
}
