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
    
    @State private var moimInfo: MoimSearchResultUIModel?
    @State private var player: AVPlayer?
    @State private var playerLooper: NSObjectProtocol?
    @State private var isBuffering: Bool = true
    @State private var showCommentSheet: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
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
            
            LinearGradient(colors: [.clear, .black.opacity(0.9)],
                           startPoint: .init(x: 0.5, y: 0.7),
                           endPoint: .init(x: 0.5, y: 0.9))
                .allowsHitTesting(false)
            
            HStack(alignment: .bottom, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        RemoteImage(
                            url: moimInfo?.imageURL ?? "",
                            displayMode: .thumbnail(CGSize(width: 16, height: 16))
                        ) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                        .background(.white.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                        Text((moimInfo == nil) ? "--" : moimInfo?.title ?? "모임 이름 없음")
                            .font(.system(size: 15)).bold()
                            .lineLimit(2)
                    }
                    .frame(height: 50)
                    
                    Text(shortVideo.content.components(separatedBy: "#").first ?? "")
                        .font(.system(size: 14))
                        .lineLimit(3)
                        .lineSpacing(3)
                    
                    HStack {
                        Image(systemName: "calendar")
                        Text(shortVideo.createdDate?.toString(format: "yy년 MM월 dd일") ?? "")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 15) {
                    ShortVideoLikeButton(
                        isLiked: $localIsLiked,
                        count: $localLikeCount,
                        action: { newValue in
                            handleLikeAction(isLiked: newValue)
                        }
                    )
                    
                    Button {
                        print("댓글 버튼 탭")
                        showCommentSheet = true
                    } label: {
                        VStack {
                            Image(systemName: "message")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                            
                            Text("\(shortVideo.commentCount)")
                                .font(.system(size: 14)).fontWeight(.medium)
                        }
                    }
                    
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
            updateMoimInfo()
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
        .sheet(isPresented: $showCommentSheet) {
            ShortVideoCommentView(videoID: shortVideo.id)
                .adaptiveCommentSheetStyle
                .presentationDetents([.fraction(0.7), .large])
                .presentationDragIndicator(.visible)
                .background(.white)
        }
        .alert("에러 발생", isPresented: $showingAlert) {
            Button("확인", role: .cancel) { return }
        } message: {
            Text(alertMessage)
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
                alertMessage = error.localizedDescription
                showingAlert = true
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
            if let updatedVideo = try? await networkService.request(router, responseType: PostResponseDTO.self).asShortVideoItem {
                await MainActor.run {
                    // shortVideo 객체를 새 객체로 갈아끼울 때, 원래의 preloader를 이용해서 delegate의 preloader를 다시 세팅해 주어야 한다.
                    // 만에 하나 없는 경우에는 메모리를 사용하도록 구현
                    // 이러한 구조는 개선이 필요하긴 할 듯..
                    let originalPreloader = self.shortVideo.resourceLoaderDelegate.preloader ?? ShortVideoMemoryPreloader.shared
                    updatedVideo.setPreloader(originalPreloader)
                    self.shortVideo = updatedVideo
                    self.syncLikeState()
                }
            }
        }
    }
    
    private func updateMoimInfo() {
        let router = PostRouter.getPost(postID: shortVideo.moimID)
        Task {
            do {
                moimInfo = try await networkService.request(router, responseType: PostResponseDTO.self).asSearchResultUIModel
            } catch {
                print("숏폼에서 모임 정보 가져오기 에러: \(error.localizedDescription)")
                alertMessage = error.localizedDescription
                showingAlert = true
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
