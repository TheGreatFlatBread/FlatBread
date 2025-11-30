import Foundation
import Combine

class DeepLinkHandler: ObservableObject {
    weak var coordinator: NavigationCoordinator?

    func handle(url: URL) {
        guard let coordinator else { return }
        let action: String?
        let roomId: String?

        if let host = url.host {
            action = host
            let pathComps = url.pathComponents.filter { $0 != "/" }
            roomId = pathComps.first
        } else {
            let pathComps = url.pathComponents.filter { $0 != "/" }
            action = pathComps.first
            roomId = pathComps.count > 1 ? pathComps[1] : nil
        }

        guard let action else {
            return
        }

        switch action {
        case "chat":
            handleChatDeepLink(roomId: roomId, coordinator: coordinator)

        default:
            break
        }
    }

    // MARK: - Chat Deep Links
    private func handleChatDeepLink(roomId: String?, coordinator: NavigationCoordinator) {
        guard let roomId else {
            return
        }

        // roomId로 ChatRoomModel 조회 (로컬 Realm)
        Task {
            guard let currentUserID = UserSession.shared.currentUserId else {
                await MainActor.run {
                    coordinator.switchTab(to: .profile, andNavigate: .profile(.chatList))
                }
                return
            }

            if let room = ChatRoomRepository.shared.getRoom(id: roomId) {
                await MainActor.run {
                    coordinator.switchTab(to: .profile, andNavigate: .profile(.chatRoom(room)))
                }
            } else {
                await MainActor.run {
                    coordinator.switchTab(to: .profile, andNavigate: .profile(.chatList))
                }
            }
        }
    }
}
