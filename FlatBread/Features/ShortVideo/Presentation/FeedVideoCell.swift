//
//  FeedVideoCell.swift
//  FlatBread
//
//  Created by 김민성 on 11/20/25.
//

import SwiftUI
import AVFoundation
import Alamofire

struct FeedVideoCell: View {
    let video: ShortFormVideo
    let bottomInset: CGFloat
    @Binding var currentVideoID: UUID?
    
    @State private var player: AVPlayer?
    @State private var resourceLoaderDelegate = CustomResourceLoaderDelegate()
    
    /// 이 뷰가 지금 화면에 보이고 있는지 여부
    var isVisible: Bool {
        return currentVideoID == video.id
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
                    Text(video.description)
                        .font(.subheadline)
                        .lineLimit(2)
                    
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
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                player?.play()
            } else {
                player?.pause()
                player?.seek(to: .zero)
            }
        }
    }
    
    private func setupPlayer() {
        if player == nil {
            // 오디오 세션 설정 (매너모드에서도 소리 나게)
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try? AVAudioSession.sharedInstance().setActive(true)
            
            // 더미 URL.
            // 실제 URL은 resourceLoaderDelegate에서 filePath를 Network Layer에 넘겨줌.
            // AVPlayer가 사용할 URL을 직접 사용하지 않고 Delegate에 위임하도록 가짜 URL 커스텀
            let dummyURL = URL(string: "custom-https://www.dummyURL.com/sample/video.mp4")!
            let asset = AVURLAsset(url: dummyURL)
            let queue = DispatchQueue(label: "com.flatBread.resourceLoader")
            
            resourceLoaderDelegate.videoFilePath = video.filePath
            asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: queue)
            let item = AVPlayerItem(asset: asset)
            player = AVPlayer(playerItem: item)
        }
        
        // 무한 반복
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            player?.seek(to: .zero)
            player?.play()
        }
        
        if isVisible {
            player?.play()
        }
    }
}
