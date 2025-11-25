//
//  ShortVideoFeedCell.swift
//  FlatBread
//
//  Created by 김민성 on 11/20/25.
//

import SwiftUI
import AVFoundation
import Combine
import Alamofire

struct ShortVideoFeedCell: View {
    
    let bottomInset: CGFloat
    
    @Binding var shortVideo: ShortVideo
    @Binding var currentVideo: ShortVideo?
    @Binding var myProfile: ShortVideoProfile?
    
    // UI 상태 관리 (낙관적 UI용)
    @State private var localIsLiked: Bool = false
    @State private var localLikeCount: Int = 0
    
    @State private var player: AVPlayer?
    @State private var playerLooper: NSObjectProtocol?
    @State private var isBuffering: Bool = true
    @State private var statusObserver: NSKeyValueObservation?
    @State private var cancellables: Set<AnyCancellable> = []
    
    private let playerManager = PlayerManager.shared
    let networkService = NetworkServiceFactory.shared.makeNetworkService()
    
    /// 이 뷰가 지금 화면에 보이고 있는지 여부
    var isVisible: Bool {
        return currentVideo?.id == shortVideo.id
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black
            
            if let player = player {
                VStack(spacing: 0) {
                    ShortVideoPlayer(player: player)
                    // 동영상 간 separator 역할
                    Color.black
                        .frame(height: 2)
                }
            }
            
            if isBuffering {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .tint(.white)
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    ShortVideoLikeButton(
                        isLiked: $localIsLiked,
                        count: $localLikeCount,
                        action: { newValue in
                            handleLikeAction(isLiked: newValue)
                        }
                    )
                    
                    ShortVideoActionButton(icon: "message", text: "Reply")
                    ShortVideoActionButton(icon: "paperplane", text: "Share")
                    
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
            syncLikeState()
            updateVideoInfo()
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
        .onChange(of: shortVideo.likes) { oldValue, newValue in
            syncLikeState()
        }
    }
    
    // MARK: - Like Logic
    
    private func syncLikeState() {
        guard let myProfile else { return }
        self.localIsLiked = shortVideo.likes.contains(myProfile.id)
        self.localLikeCount = shortVideo.likes.count
    }
    
    private func handleLikeAction(isLiked: Bool) {
        guard let myProfile else { return }

        // 데이터 모델 즉시 업데이트 (로컬 반영) -> 나갔다 들어와도 유지되게
        if isLiked {
            if !shortVideo.likes.contains(myProfile.id) {
                shortVideo.likes.append(myProfile.id)
            }
        } else {
            shortVideo.likes.removeAll { $0 == myProfile.id }
        }
        
        // 서버에 좋아요 변경 요청
        Task {
            let router = PostRouter.togglePostLikeV1(
                postID: shortVideo.id,
                like_status: isLiked
            )
            do {
                let _ = try await networkService.request(router, responseType: LikeResponseDTO.self).likeStatus
            } catch {
                print("❌ 좋아요 요청 실패: \(error)")
                rollbackLikeState(to: !isLiked)
            }
        }
    }
    
    private func rollbackLikeState(to failedState: Bool) {
        guard let myProfile else { return }
        
        Task { @MainActor in
            let originalState = !failedState
            self.localIsLiked = originalState
            
            // 숫자 및 데이터 모델 원복
            if originalState {
                if !shortVideo.likes.contains(myProfile.id) {
                    shortVideo.likes.append(myProfile.id)
                    self.localLikeCount += 1
                }
            } else {
                if shortVideo.likes.contains(myProfile.id) {
                    shortVideo.likes.removeAll { $0 == myProfile.id }
                    self.localLikeCount -= 1
                }
            }
            print("⚠️ 네트워크 오류로 좋아요 상태가 복구되었습니다.")
        }
    }
    
    private func updateVideoInfo() {
        let router = PostRouter.getPost(postID: shortVideo.id)
        Task {
            if let updatedDTO = try? await networkService.request(router, responseType: PostResponseDTO.self) {
                await MainActor.run {
                    self.shortVideo.likes = updatedDTO.likes
                    self.syncLikeState()
                }
            }
        }
    }
    
    private func setupPlayer(with video: ShortVideo) {
        // 오디오 세션 설정 (매너모드에서도 소리 나게)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
        
        let player = playerManager.player(for: video)
        self.player = player
        
        isBuffering = (player.timeControlStatus != .playing)
        
        player.publisher(for: \.timeControlStatus)
            .receive(on: RunLoop.main)
            .sink { status in
                switch status {
                case .waitingToPlayAtSpecifiedRate:
                    self.isBuffering = true
                case .playing, .paused:
                    self.isBuffering = false
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
        
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
        cancellables = []
        playerManager.deactivatePlayer(for: shortVideo)
        self.player = nil
        
        if let playerLooper {
            NotificationCenter.default.removeObserver(playerLooper)
            self.playerLooper = nil
        }
        
    }
    
}
