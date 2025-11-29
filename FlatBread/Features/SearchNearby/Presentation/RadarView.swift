//
//  RadarView.swift
//  FlatBread
//
//  Created by 김민성 on 11/27/25.
//

// RadarView.swift
import SwiftUI
import MultipeerConnectivity

enum FindNearbyRoute: Hashable {
    case moveToChat(partnerID: String)
}

struct RadarView: View {
    @StateObject private var service = NearbyService()
    @Binding var navigationPath: NavigationPath
    
    // UI Local State
    @State private var selectedPeer: PeerUser?
    @State private var showConfirmAlert: Bool = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            if service.state == .initializing {
                ProgressView("준비 중...")
            } else {
                mainRadarContent
            }
            
            // 로딩 오버레이 (프로필 페치 or 연결 중)
            if case .fetchingProfile = service.state {
                loadingOverlay(msg: "프로필 불러오는 중...")
            } else if case .connecting = service.state {
                loadingOverlay(msg: "연결 중...")
            } else if case .inviting = service.state {
                loadingOverlay(msg: "응답 기다리는 중...")
            }
        }
        .navigationTitle("주변 탐색")
        .task {
            // 네비게이션 콜백 연결
            service.onMoveToChat = { partnerID in
                navigationPath.append(FindNearbyRoute.moveToChat(partnerID: partnerID))
            }
            await service.fetchMyIDAndStart()
        }
        .onDisappear {
            service.cleanup()
        }
        // 1. [발신자] 보내기 확인 Alert
        .alert("대화 요청", isPresented: $showConfirmAlert) {
            Button("요청 보내기") {
                if let peer = selectedPeer {
                    service.invitePeer(peer)
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("\(selectedPeer?.mcPeerID.displayName ?? "")님에게 요청하시겠습니까?")
        }
        // 2. [수신자] 요청 받음 Alert
        // Binding 계산 로직 제거 -> 상태 감지용 Binding 사용
        .alert("채팅 요청", isPresented: Binding(
            get: { if case .responding = service.state { return true } else { return false } },
            set: { _ in } // 버튼 액션에서 상태를 바꾸므로 set은 무시
        )) {
            Button("수락") {
                service.respondToInvitation(accept: true)
            }
            Button("거절", role: .cancel) {
                service.respondToInvitation(accept: false)
            }
        } message: {
            if case .responding(let user) = service.state {
                Text("\(user.fbUserID)님이 대화를 요청했습니다.")
            }
        }
        // 3. [공통] 에러/정보 Alert
        .alert("알림", isPresented: $service.showAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(service.alertMessage ?? "")
        }
        // 4. 네비게이션 목적지
        .navigationDestination(for: FindNearbyRoute.self) { route in
            if case .moveToChat(let id) = route {
                ChatView(partnerID: id)
            }
        }
    }
    
    // 본문 뷰 분리
    var mainRadarContent: some View {
        VStack {
            Spacer()
            ZStack {
                RadarBackgroundCircles()
                FindNearbyMyIconView(id: service.myMCPeerID?.displayName ?? "Me")
                
                GeometryReader { geo in
                    let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                    let radius = min(geo.size.width, geo.size.height)/2
                    
                    ForEach(service.detectedUsers) { peer in
                        FindNearbyPeerIconView(peer: peer)
                            .position(
                                x: center.x + cos(peer.angle * .pi/180) * (radius * peer.distanceFactor),
                                y: center.y + sin(peer.angle * .pi/180) * (radius * peer.distanceFactor)
                            )
                            .onTapGesture {
                                // Idle 상태일 때만
                                if case .idle = service.state {
                                    self.selectedPeer = peer
                                    self.showConfirmAlert = true
                                }
                            }
                            .opacity(service.state.isBusy ? 0.3 : 1.0)
                            .grayscale(service.state.isBusy ? 1.0 : 0.0)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            Spacer()
        }
    }
    
    func loadingOverlay(msg: String) -> some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack {
                ProgressView()
                    .tint(.white)
                Text(msg)
                    .foregroundColor(.white)
                    .padding(.top, 8)
            }
        }
    }
}


// 더미 채팅 뷰
struct ChatView: View {
    let partnerID: String
    
    var body: some View {
        VStack {
            Text("\(partnerID)님과의 채팅")
                .font(.title)
            Spacer()
        }
    }
}

//#Preview {
//    @Previewable @State var navigationPath = NavigationPath()
//    RadarView(navigationPath: $navigationPath)
//}
