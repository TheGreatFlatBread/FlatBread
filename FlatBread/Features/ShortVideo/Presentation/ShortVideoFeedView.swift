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
                    ForEach($viewModel.shortVideos) { video in
                        ShortVideoFeedCell(bottomInset: proxy.safeAreaInsets.bottom,
                                      shortVideo: video,
                                      currentVideo: $viewModel.currentVideo,
                                      myProfile: $viewModel.myProfile,
                                           isLongPressing: $viewModel.isLongPressing)
                            .containerRelativeFrame([.horizontal, .vertical])
                            .id(video.wrappedValue)
                    }
                }
                .ignoresSafeArea()
                .scrollTargetLayout()
            }
            .scrollDisabled(viewModel.isLongPressing)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $viewModel.currentVideo)
            .ignoresSafeArea()
            .background(Color.black)
            .onAppear {
                UIScrollView.appearance().scrollsToTop = false
            }
            .task {
                await viewModel.updateShortVideos()
                if viewModel.currentVideo == nil {
                    viewModel.currentVideo = viewModel.shortVideos.first
                }
            }
            .onDisappear {
                UIScrollView.appearance().scrollsToTop = true
            }
        }
    }
}


