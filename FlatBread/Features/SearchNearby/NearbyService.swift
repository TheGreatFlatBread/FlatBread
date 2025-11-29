//
//  NearbyService.swift
//  FlatBread
//
//  Created by 김민성 on 11/27/25.
//

import Combine
import Foundation
import MultipeerConnectivity
import SwiftUI

class NearbyService: NSObject, ObservableObject {
    
    enum ConnectionSignal: Codable {
        case accept
        case decline
    }
    
    private let serviceType = "nearby-chat"
    
    // UI 상태
    @Published var state: NearbyServiceState = .initializing
    @Published var detectedUsers: [PeerUser] = []
    
    // 내 정보
    @Published var myMCPeerID: MCPeerID?
    private var myFbUserID: String = "" // Context 전송용
    
    // Alert 제어
    @Published var alertMessage: String? = nil
    @Published var showAlert: Bool = false
    
    // MPC Core
    private var serviceAdvertiser: MCNearbyServiceAdvertiser?
    private var serviceBrowser: MCNearbyServiceBrowser?
    
    // Session은 하나로만 관리: 필요할 때 만들고 바로 없앰
    private var session: MCSession?
    
    // 초대 핸들러 저장 (수락/거절 시 사용)
    private var invitationHandler: ((Bool, MCSession?) -> Void)?
    
    // 의도적인 연결 종료인지 확인하는 플래그 (에러 알림 방지)
    private var isDisconnectingIntentionally: Bool = false
    
    // 네비게이션 트리거
    var onMoveToChat: ((String) -> Void)?
    
    // MARK: - Setup
    @MainActor
    func fetchMyIDAndStart() async {
        self.state = .initializing
        cleanup()
        
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        let userID = "69159b50ff94927948ff0fb1" // 우선 임시 더미 값 활용
        self.myFbUserID = userID
        self.myMCPeerID = MCPeerID(displayName: "익명의 유저")
        
        startMPC()
        self.state = .idle
    }
    
    private func startMPC() {
        guard let myMCPeerID else { return }
        
        let discoveryInfo: [String: String] = ["fbUserID": myFbUserID]
        
        serviceAdvertiser = MCNearbyServiceAdvertiser(
            peer: myMCPeerID,
            discoveryInfo: discoveryInfo,
            serviceType: serviceType
        )
        serviceAdvertiser?.delegate = self
        serviceAdvertiser?.startAdvertisingPeer()
        
        serviceBrowser = MCNearbyServiceBrowser(peer: myMCPeerID, serviceType: serviceType)
        serviceBrowser?.delegate = self
        serviceBrowser?.startBrowsingForPeers()
    }
    
    // MARK: - User Actions
    
    func invitePeer(_ peerUser: PeerUser) {
        guard case .idle = state, let browser = serviceBrowser else { return }
        
        createSession(targetPeer: peerUser.mcPeerID)
        
        self.state = .inviting(peerUser)
        
        let contextData = myFbUserID.data(using: .utf8)
        browser.invitePeer(
            peerUser.mcPeerID,
            to: self.session!,
            withContext: contextData,
            timeout: 30
        )
    }
    
    func respondToInvitation(accept: Bool) {
        guard case .responding(let peerUser) = state,
              let handler = invitationHandler else { return }
        
        createSession(targetPeer: peerUser.mcPeerID)
        
        if accept {
            // 수락: 연결 후 .accept 메시지를 보내야 함
            // 상태를 connecting으로 변경하여 UI 블락
            self.state = .connecting(peerUser)
            handler(true, self.session)
        } else {
            // 거절: 연결 후 .decline 메시지를 보내야 함
            // 여기서도 일단 true로 연결해야 메시지를 보낼 수 있음
            self.isDisconnectingIntentionally = true
            self.state = .connecting(peerUser)
            handler(true, self.session)
        }
        
        self.invitationHandler = nil
    }
    
    // MARK: - Helpers
    
    private func createSession(targetPeer: MCPeerID) {
        // 기존 세션 정리
        session?.disconnect()
        
        // 새 세션
        let newSession = MCSession(peer: myMCPeerID!, securityIdentity: nil, encryptionPreference: .required)
        newSession.delegate = self
        self.session = newSession
        self.isDisconnectingIntentionally = false // 리셋
    }
    
    // 우선 더미로 구현
    private func fetchUserProfile(fbUserID: String) {
        Task { @MainActor in
            self.state = .fetchingProfile(fbUserID)
            // 더미 딜레이
            try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
            
            self.onMoveToChat?(fbUserID)
            self.state = .chatting(fbUserID)
            
            // 채팅방 이동했으므로 MPC 세션은 더 이상 필요 없음
            self.cleanupSessionOnly()
        }
    }
    
    // 세션만 정리 (탐색은 계속)
    private func cleanupSessionOnly() {
        isDisconnectingIntentionally = true // 의도된 종료
        session?.disconnect()
        session = nil
    }
    
    // 전체 정리 (화면 나갈 때)
    func cleanup() {
        cleanupSessionOnly()
        serviceAdvertiser?.stopAdvertisingPeer()
        serviceBrowser?.stopBrowsingForPeers()
        detectedUsers.removeAll()
        state = .idle
    }
    
    // 신호 전송
    private func sendSignal(_ signal: ConnectionSignal, to peers: [MCPeerID]) {
        guard let session, !peers.isEmpty else { return }
        do {
            let data = try JSONEncoder().encode(signal)
            try session.send(data, toPeers: peers, with: .reliable)
        } catch {
            print("Signal send failed: \(error)")
        }
    }
}

// MARK: - Browser Delegate
extension NearbyService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard let info, let fbUserID = info["fbUserID"] else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if !self.detectedUsers.contains(where: { $0.fbUserID == fbUserID }) {
                let newPeerUser = PeerUser(mcPeerID: peerID, fbUserID: fbUserID)
                withAnimation { self.detectedUsers.append(newPeerUser) }
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            withAnimation {
                self.detectedUsers.removeAll(where: { $0.mcPeerID == peerID })
            }
            
            // 만약 초대 중인 대상이 사라지면 에러 처리
            if case .inviting(let peer) = self.state, peer.mcPeerID == peerID {
                self.alertMessage = "상대방을 찾을 수 없습니다."
                self.showAlert = true
                self.state = .idle
                self.cleanupSessionOnly()
            }
        }
    }
}

// MARK: - Advertiser Delegate
extension NearbyService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            // 이미 다른 작업 중이면 자동 거절
            if self.state.isBusy {
                print("Busy state, auto declining: \(peerID.displayName)")
                invitationHandler(false, nil)
                return
            }
            
            // Context에서 상대방 ID 확인
            var remoteFbUserID = "Unknown"
            if let data = context, let idString = String(data: data, encoding: .utf8) {
                remoteFbUserID = idString
            }
            
            // User 객체 구성 (목록에 없어도 생성)
            let peerUser = self.detectedUsers.first(where: { $0.mcPeerID == peerID })
                ?? PeerUser(mcPeerID: peerID, fbUserID: remoteFbUserID)
            
            self.invitationHandler = invitationHandler
            self.state = .responding(peerUser) // UI Alert 트리거
        }
    }
}

// MARK: - MCSession Delegate
extension NearbyService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // 현재 활성화된 세션의 이벤트인지 확인
            guard self.session == session else { return }
            
            switch state {
            case .connected:
                print("Connected to \(peerID.displayName)")
                
                // 연결되면 즉시 상태에 따라 신호 전송
                // 내가 초대를 받은 입장 (responding -> connecting 상태였음)
                if case .connecting(let user) = self.state {
                    // 거절하려고 연결한 경우
                    if self.isDisconnectingIntentionally {
                        self.sendSignal(.decline, to: [peerID])
                        // 전송 보장을 위해 잠시 후 연결 끊기
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.cleanupSessionOnly()
                            self.state = .idle
                        }
                    }
                    // 수락해서 연결한 경우
                    else {
                        self.sendSignal(.accept, to: [peerID])
                        // 나는 수락했으니 상대방이 프로필을 가져가도록 대기하지 않고,
                        // 나도 상대방 프로필을 가져옴 (양방향)
                        self.fetchUserProfile(fbUserID: user.fbUserID)
                    }
                }
                
                // 내가 초대를 보낸 입장 (inviting 상태) -> 아무것도 안 하고 상대의 신호 대기
                
            case .notConnected:
                print("Disconnected from \(peerID.displayName)")
                
                // 이미 의도적으로 끊는 중이라면 무시 (채팅방 이동, 혹은 거절 후 종료)
                if self.isDisconnectingIntentionally {
                    return
                }
                
                // 비정상 종료 처리
                if case .inviting = self.state {
                    // 상대가 거절 신호 없이 그냥 끊음 (타임아웃 or 거절 누름)
                    // (보통 decline 신호를 먼저 받지만, 네트워크 사정상 끊김이 먼저 올 수도 있음)
                    self.alertMessage = "연결이 거절되었거나 실패했습니다."
                    self.showAlert = true
                } else if case .connecting = self.state {
                    self.alertMessage = "연결 중 오류가 발생했습니다."
                    self.showAlert = true
                }
                
                self.state = .idle
                self.session = nil
                
            default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let signal = try? JSONDecoder().decode(ConnectionSignal.self, from: data) else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard self.session == session else { return }
            
            switch signal {
            case .accept:
                // 상대방이 수락함 (내가 Inviting 상태였을 것)
                if case .inviting(let user) = self.state {
                     self.fetchUserProfile(fbUserID: user.fbUserID)
                }
                
            case .decline:
                // 상대방이 거절함
                self.isDisconnectingIntentionally = true // 이 끊김은 에러가 아님
                self.alertMessage = "\(peerID.displayName)님이 거절했습니다."
                self.showAlert = true
                
                self.cleanupSessionOnly()
                self.state = .idle
            }
        }
    }
    
    // 미사용된 필수 메서드
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
