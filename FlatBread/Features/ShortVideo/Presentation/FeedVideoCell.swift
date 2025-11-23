//
//  FeedVideoCell.swift
//  FlatBread
//
//  Created by 김민성 on 11/20/25.
//

import SwiftUI
import AVFoundation
import Combine
import Alamofire

struct FeedVideoCell: View {
    let shortVideo: ShortVideo
    let bottomInset: CGFloat
    @Binding var currentVideoID: String?
    
    @State private var player: AVPlayer?
    @State private var playerLooper: NSObjectProtocol?
    @State private var statusObserver: NSKeyValueObservation?
    @State private var cancellables: Set<AnyCancellable> = []
    
    private let playerManager = PlayerManager.shared
    
    /// 이 뷰가 지금 화면에 보이고 있는지 여부
    var isVisible: Bool {
        return currentVideoID == shortVideo.id
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if let player = player {
                VStack(spacing: 0) {
                    ShortFormVideoPlayer(player: player)
                    // 동영상 간 separator 역할
                    Color.black
                        .frame(height: 2)
                }
            } else {
                Color.black
            }
            
            LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .center, endPoint: .bottom)
                .allowsHitTesting(false)
            
            HStack(alignment: .bottom, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable().frame(width: 32, height: 32)
                        Text("@user_id")
                            .font(.headline).bold()
                    }
                    Text(shortVideo.content)
                        .font(.subheadline)
                        .lineLimit(3)
                    
                    HStack {
                        Image(systemName: "music.note")
                        Text("Original Audio - Trending")
                            .font(.caption)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 25) {
                    ShortFormActionButton(icon: "heart", text: "Like")
                    ShortFormActionButton(icon: "message", text: "Reply")
                    ShortFormActionButton(icon: "paperplane", text: "Share")
                    
                    Image(systemName: "opticaldisc.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .rotationEffect(.degrees(isVisible ? 360 : 0))
                        .animation(isVisible ? .linear(duration: 5).repeatForever(autoreverses: false) : .default, value: isVisible)
                }
                .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.bottom, bottomInset + 20)
        }
        .onAppear {
            setupPlayer(with: shortVideo)
        }
        .onDisappear {
            releasePlayer()
        }
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                player?.play()
            } else {
                playerManager.pause(for: shortVideo)
            }
        }
    }
    
    private func setupPlayer(with video: ShortVideo) {
        // 오디오 세션 설정 (매너모드에서도 소리 나게)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
        
        let player = playerManager.player(for: video)
        self.player = player
        
        if let playerLooper {
            NotificationCenter.default.removeObserver(playerLooper)
        }
        
        playerLooper = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        
        if isVisible {
            player.play()
        }
    }
    
    private func releasePlayer() {
        playerManager.deactivatePlayer(for: shortVideo)
        self.player = nil
        
        if let playerLooper {
            NotificationCenter.default.removeObserver(playerLooper)
            self.playerLooper = nil
        }
        
        cancellables = []
    }
    
}
