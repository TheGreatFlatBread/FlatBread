import Foundation

/// 채팅방별 동기화 작업을 중앙에서 관리하는 싱글톤
/// - 중복 sync 방지
/// - 진행 중인 sync 작업 재사용
final class ChatSyncManager {
    static let shared = ChatSyncManager()
    private init() {}

    // 현재 진행 중인 sync Task들 (roomID: Task)
    private var syncTasks: [String: Task<Void, Never>] = [:]
    private let syncQueue = DispatchQueue(label: "com.flatbread.chatSyncManager", attributes: .concurrent)

    /// 채팅방 메시지 동기화
    /// - 이미 진행 중이면 기존 Task를 await
    /// - 새로운 sync면 Task 생성 후 저장
    func syncMessages(
        roomID: String,
        participants: [ChatUserModel],
        createdAt: String,
        networkService: AsyncNetworkService
    ) async {
        // 이미 진행 중인 Task가 있으면 기다림
        if let existingTask = getTask(for: roomID) {
            print("이미 동기화 중 - 기존 작업 대기: \(roomID)")
            await existingTask.value
            return
        }

        // 새 Task 생성
        let task = Task { @MainActor in
            await performSync(
                roomID: roomID,
                participants: participants,
                createdAt: createdAt,
                networkService: networkService
            )
        }

        setTask(task, for: roomID)
        await task.value
        removeTask(for: roomID)
    }

    /// 실제 동기화 로직
    private func performSync(
        roomID: String,
        participants: [ChatUserModel],
        createdAt: String,
        networkService: AsyncNetworkService
    ) async {
        print("메시지 동기화 시작: \(roomID)")

        do {
            let messageRepository = ChatMessageRepository.shared
            let lastMessage = messageRepository.getLastMessage(roomID: roomID, participants: participants)
            let cursor = lastMessage?.createdAt ?? createdAt

            let response = try await networkService.request(
                ChatRouter.fetchChatMessgeList(roomID: roomID, cursorDate: cursor),
                responseType: ChatMessageListResponseDTO.self,
                interceptorType: .networkWithToken
            )

            let newMessages = response.data.map { $0.toVM() }

            if !newMessages.isEmpty {
                messageRepository.saveMessages(newMessages)
                print("메시지 \(newMessages.count)개 동기화 완료: \(roomID)")
            } else {
                print("새 메시지 없음: \(roomID)")
            }
        } catch {
            print("메시지 동기화 실패: \(roomID), \(error)")
        }
    }

    private func getTask(for roomID: String) -> Task<Void, Never>? {
        syncQueue.sync {
            syncTasks[roomID]
        }
    }

    private func setTask(_ task: Task<Void, Never>, for roomID: String) {
        syncQueue.async(flags: .barrier) {
            self.syncTasks[roomID] = task
        }
    }

    private func removeTask(for roomID: String) {
        syncQueue.async(flags: .barrier) {
            self.syncTasks[roomID] = nil
        }
    }

    /// 현재 동기화 중인 채팅방 목록
    var syncingRoomIDs: [String] {
        syncQueue.sync {
            Array(syncTasks.keys)
        }
    }

    /// 특정 채팅방이 동기화 중인지 확인
    func isSyncing(roomID: String) -> Bool {
        getTask(for: roomID) != nil
    }
}
