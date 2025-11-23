//
//  ShortVideoFeedView.swift
//  FlatBread
//
//  Created by 김민성 on 11/20/25.
//

import SwiftUI

struct ShortVideoFeedView: View {
    
    @StateObject private var viewModel = ShortVideoFeedViewModel()
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.shortVideos) { video in
                        FeedVideoCell(shortVideo: video,
                                      bottomInset: proxy.safeAreaInsets.bottom,
                                      currentVideoID: $viewModel.currentVideoID)
                            .containerRelativeFrame([.horizontal, .vertical])
                            .id(video.id)
                    }
                }
                .ignoresSafeArea()
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $viewModel.currentVideoID)
            .ignoresSafeArea()
            .background(Color.black)
            .onAppear {
                UIScrollView.appearance().scrollsToTop = false
                viewModel.shortVideos = viewModel.shortVideosResponseDummy.map(\.asShortVideoItem)
                if viewModel.currentVideoID == nil {
                    viewModel.currentVideoID = viewModel.shortVideos.first?.id
                }
            }
            .onDisappear {
                UIScrollView.appearance().scrollsToTop = true
            }
        }
    }
}


