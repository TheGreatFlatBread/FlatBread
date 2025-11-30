import Foundation
import Combine

class DeepLinkHandler: ObservableObject {
    weak var coordinator: NavigationCoordinator?

    func handle(url: URL) {
        guard let coordinator = coordinator else { return }

        print("[DeepLink] URL 수신: \(url.absoluteString)")
        print("[DeepLink]    - host: \(url.host ?? "nil")")
        print("[DeepLink]    - pathComponents: \(url.pathComponents)")

        // URL 파싱: host 또는 pathComponents 사용
        let action: String?
        let roomId: String?

        if let host = url.host {
            // FlatBread://chat/roomId 형식
            action = host
            let pathComps = url.pathComponents.filter { $0 != "/" }
            roomId = pathComps.first
        } else {
            // FlatBread:///chat/roomId 형식 (host 없음)
            let pathComps = url.pathComponents.filter { $0 != "/" }
            action = pathComps.first
            roomId = pathComps.count > 1 ? pathComps[1] : nil
        }

        guard let action = action else {
            print("[DeepLink] action을 파싱할 수 없음")
            return
        }

        print("[DeepLink]    - action: \(action)")
        print("[DeepLink]    - roomId: \(roomId ?? "nil")")

        switch action {
        case "chat":
            handleChatDeepLink(roomId: roomId, coordinator: coordinator)

        default:
            print("[DeepLink] 지원하지 않는 deeplink action: \(action)")
            break
        }
    }

    // MARK: - Chat Deep Links
    private func handleChatDeepLink(roomId: String?, coordinator: NavigationCoordinator) {
        guard let roomId else {
            print("[DeepLink] roomId 없음")
            return
        }

        // roomId로 ChatRoomModel 조회 (로컬 Realm)
        Task {
            guard let currentUserID = UserSession.shared.currentUserId else {
                print("[DeepLink] 로그인 안 됨 - 채팅 리스트로 이동")
                await MainActor.run {
                    coordinator.switchTab(to: .profile, andNavigate: .profile(.chatList))
                }
                return
            }

            if let room = ChatRoomRepository.shared.getRoom(id: roomId) {
                print("[DeepLink] 채팅방 찾음: \(roomId)")
                await MainActor.run {
                    coordinator.switchTab(to: .profile, andNavigate: .profile(.chatRoom(room)))
                }
            } else {
                print("[DeepLink] 로컬에 채팅방 없음 - 채팅 리스트로 이동")
                await MainActor.run {
                    coordinator.switchTab(to: .profile, andNavigate: .profile(.chatList))
                }
            }
        }
    }
}
