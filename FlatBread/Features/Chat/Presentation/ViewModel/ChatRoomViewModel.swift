//
//  ChatRoomDetailViewModel.swift
//  FlatBread
//
//  Created by hwan on 11/14/25.
//

import SwiftUI
import Combine
import HwanCache

final class ChatRoomViewModel: ObservableObject {
    private(set) var room: ChatRoomModel?
    let currentUserID: String

    private let opponentID: String?
    private let opponentNick: String?
    private let opponentProfileImage: String?
    private let imageService: HWImageService

    @Published private(set) var messages: [ChatMessageModel] = []
    @Published var messageText: String = ""
    @Published var isLoadingMore: Bool = false
    @Published var scrollPosition: String = ""
    @Published var chatItems: [ChatItem] = []
    @Published var selectedImageURLs: [String] = []
    @Published var isCreatingRoom: Bool = false
    @Published var isWebSocketConnected: Bool = false

    private var currentPageOffset: Int = 0
    private var cursorDate: String?
    private var hasMoreOlderMessages: Bool = true

    private var messageQueue: [ChatMessageResponseDTO] = []
    private var isRealmSynced = false

    private var connectionTask: Task<Void, Never>?
    private var messageTask: Task<Void, Never>?

    private let networkService: AsyncNetworkService
    private let messageRepository = ChatMessageRepository.shared
    private let roomRepository = ChatRoomRepository.shared
    private let webSocketManager = ChatWebSocketManager.shared

    var displayTitle: String {
        room?.participants.first { $0.id != currentUserID }?.nick
            ?? opponentNick
            ?? "채팅방"
    }

    var isEmpty: Bool {
        messages.isEmpty && chatItems.isEmpty
    }
    
    deinit {
        print("chatRoomViewModel deinit")
    }

    init(room: ChatRoomModel, currentUserID: String, imageService: HWImageService) {
        self.room = room
        self.currentUserID = currentUserID
        self.opponentID = nil
        self.opponentNick = nil
        self.opponentProfileImage = nil
        self.networkService = NetworkServiceFactory.shared.makeNetworkService()
        self.imageService = imageService
    }

    init(opponentID: String, opponentNick: String, opponentProfileImage: String?, currentUserID: String, imageService: HWImageService) {
        self.room = nil
        self.currentUserID = currentUserID
        self.opponentID = opponentID
        self.opponentNick = opponentNick
        self.opponentProfileImage = opponentProfileImage
        self.networkService = NetworkServiceFactory.shared.makeNetworkService()
        self.imageService = imageService
    }

    func sendMessage() {
        guard !messageText.isEmpty || !selectedImageURLs.isEmpty else { return }

        if room == nil {
            createRoomAndSend()
        } else if !selectedImageURLs.isEmpty {
            sendMessageWithImages()
        } else {
            sendTextOnly()
        }
    }

    private func createRoomAndSend() {
        guard let opponentID else { return }

        let pendingText = messageText
        let pendingImages = selectedImageURLs

        messageText = ""
        selectedImageURLs.removeAll()
        isCreatingRoom = true

        Task {
            do {
                let response = try await networkService.request(
                    ChatRouter.makeChatRoom(opponent_id: opponentID),
                    responseType: ChatResponseDTO.self,
                    interceptorType: .networkWithToken
                )
                self.room = response.toVM()

                // Realm에 새 채팅방 저장
                if let room = self.room {
                    roomRepository.saveRoom(room)
                }

                isCreatingRoom = false

                // room 생성 후 메시지 전송
                messageText = pendingText
                selectedImageURLs = pendingImages

                if !pendingImages.isEmpty {
                    sendMessageWithImages()
                } else {
                    sendTextOnly()
                }
            } catch {
                isCreatingRoom = false
                messageText = pendingText
                selectedImageURLs = pendingImages
            }
        }
    }

    func removeImage(at index: Int) {
        guard index < selectedImageURLs.count else { return }
        let urlToRemove = selectedImageURLs[index]
        selectedImageURLs.remove(at: index)

        if urlToRemove.hasPrefix("file://") {
            // 파일 시스템에서 원본 삭제
            ImageFileManager.shared.deleteImage(at: urlToRemove)
        }

        // 캐시에서 삭제 (file://도 캐시에 있을 수 있음)
        Task {
            await imageService.removeFromCache(url: urlToRemove)
        }
    }
    
    func fetchAndSync() async {
        guard let room, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let lastMessage = messageRepository.getLastMessage(roomID: room.id, participants: room.participants)
            let cursor = lastMessage?.createdAt ?? room.createdAt

            let response = try await networkService.request(
                ChatRouter.fetchChatMessgeList(roomID: room.id, cursorDate: cursor),
                responseType: ChatMessageListResponseDTO.self,
                interceptorType: .networkWithToken
            )

            let newMessages = response.data.map { $0.toVM() }

            if !newMessages.isEmpty {
                messageRepository.saveMessages(newMessages)
            }

            fetchMessagesFromRealm()
            isRealmSynced = true
            processQueuedMessages()
        } catch {
            print("채팅 메시지 동기화 실패: \(error)")
        }
    }

    /// 큐에 쌓인 WebSocket 메시지 처리 (중복 체크)
    private func processQueuedMessages() {
        guard let room else { return }

        for messageDTO in messageQueue {
            let message = messageDTO.toVM()

            if messageRepository.getMessage(id: message.id, participants: room.participants) == nil {
                if message.sender.id != currentUserID {
                    addMessage(message)
                    messageRepository.saveMessage(message)
                    roomRepository.updateRoomTime(roomID: room.id, updatedAt: Date())
                }
            }
        }

        print("Processed \(messageQueue.count) queued WebSocket messages")
        messageQueue.removeAll()
    }

    // MARK: - Realm에서 메시지 로드
    /// 최초 화면 로드 시 Realm에서 최신 메시지 로드
    func fetchMessagesFromRealm() {
        guard let room else { return }

        messages.removeAll()
        chatItems.removeAll()

        let realmMessages = messageRepository
            .getLatestMessages(
                roomID: room.id,
                participants: room.participants,
                limit: 30
            )

        for message in realmMessages {
            addMessage(message)
        }

        hasMoreOlderMessages = realmMessages.count >= 30
    }

    // MARK: - 이전 메시지 로드 (페이지네이션)
    /// 스크롤 위로 시 Realm에서 이전 메시지 로드
    func loadOlderMessages() {
        guard let room, hasMoreOlderMessages, !isLoadingMore else { return }
        guard let oldestMessage = messages.first,
              let oldestDate = oldestMessage.createdAt.toDate() else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        let olderMessages = messageRepository.getOlderMessages(roomID: room.id, participants: room.participants, before: oldestDate, limit: 30)

        if olderMessages.isEmpty {
            hasMoreOlderMessages = false
            return
        }

        insertMessagesToFront(olderMessages)

        hasMoreOlderMessages = olderMessages.count >= 30
    }

    private func insertMessagesToFront(_ newMessages: [ChatMessageModel]) {
        let filteredMessages = newMessages.filter { new in
            !messages.contains(where: { $0.id == new.id })
        }
        guard !filteredMessages.isEmpty else { return }

        messages.insert(contentsOf: filteredMessages, at: 0)

        var firstExistingDateKey: String?
        var firstExistingDateHeaderIndex: Int?
        for (index, item) in chatItems.enumerated() {
            if case .dateHeader(let date, _) = item {
                firstExistingDateKey = date
                firstExistingDateHeaderIndex = index
                break
            }
        }

        let groupedByDate = Dictionary(grouping: filteredMessages) { $0.createdAt.toDateKey() }
        let sortedDates = groupedByDate.keys.sorted()

        var insertItems: [ChatItem] = []

        for dateString in sortedDates {
            guard let messagesInDate = groupedByDate[dateString] else { continue }

            // 날짜 헤더 추가 (항상 추가)
            insertItems.append(.dateHeader(date: dateString, dateFormatted: dateString.toChatSectionHeader()))

            for (idx, message) in messagesInDate.enumerated() {
                let prevMsg = idx > 0 ? messagesInDate[idx - 1] : nil
                let nextMsg = idx < messagesInDate.count - 1 ? messagesInDate[idx + 1] : nil

                let config = createDisplayConfig(
                    message: message,
                    previousMessage: prevMsg,
                    nextMessage: nextMsg
                )
                insertItems.append(.message(config: config))
            }
        }

        // 기존 첫 번째 날짜 헤더가 새로 추가한 날짜와 같으면 제거
        if let lastInsertedDate = sortedDates.last,
           lastInsertedDate == firstExistingDateKey,
           let headerIndex = firstExistingDateHeaderIndex {
            chatItems.remove(at: headerIndex)
        }

        // 맨 앞에 삽입
        chatItems.insert(contentsOf: insertItems, at: 0)

        // 경계 메시지 displayConfig 업데이트 (새 메시지 마지막 ↔ 기존 첫 메시지)
        updateBoundaryDisplayConfig(insertedCount: insertItems.count)
    }

    // MARK: - 경계 메시지 displayConfig 업데이트
    private func updateBoundaryDisplayConfig(insertedCount: Int) {
        guard insertedCount > 0, chatItems.count > insertedCount else { return }

        // 삽입된 마지막 메시지 찾기
        var lastInsertedMessageIndex: Int?
        for i in stride(from: insertedCount - 1, through: 0, by: -1) {
            if case .message = chatItems[i] {
                lastInsertedMessageIndex = i
                break
            }
        }

        // 기존 첫 메시지 찾기
        var firstExistingMessageIndex: Int?
        for i in insertedCount..<chatItems.count {
            if case .message = chatItems[i] {
                firstExistingMessageIndex = i
                break
            }
        }

        guard let lastIdx = lastInsertedMessageIndex,
              let firstIdx = firstExistingMessageIndex,
              case .message(let lastConfig) = chatItems[lastIdx],
              case .message(let firstConfig) = chatItems[firstIdx] else { return }

        // 마지막 삽입 메시지의 showTime 재계산
        let newShowTime = shouldShowTime(current: lastConfig.message, next: firstConfig.message)
        if lastConfig.showTime != newShowTime {
            let updatedConfig = MessageDisplayConfig(
                id: lastConfig.id,
                message: lastConfig.message,
                showProfile: lastConfig.showProfile,
                showNickname: lastConfig.showNickname,
                showTime: newShowTime
            )
            chatItems[lastIdx] = .message(config: updatedConfig)
        }

        // 기존 첫 메시지의 showProfile 재계산
        let newShowProfile = shouldShowProfile(current: firstConfig.message, previous: lastConfig.message)
        if firstConfig.showProfile != newShowProfile {
            let updatedConfig = MessageDisplayConfig(
                id: firstConfig.id,
                message: firstConfig.message,
                showProfile: newShowProfile,
                showNickname: newShowProfile,
                showTime: firstConfig.showTime
            )
            chatItems[firstIdx] = .message(config: updatedConfig)
        }
    }
}


// MARK: Send Logic
extension ChatRoomViewModel {
    private func sendTextOnly() {
        guard let room else { return }

        let messageContent = messageText
        let tempMessageID = UUID().uuidString

        // 현재 사용자 정보를 participants에서 조회
        let sender = room.participants.first(where: { $0.id == currentUserID })
                     ?? ChatUserModel(id: currentUserID, nick: "나", profileImage: nil)

        let tempMessage = ChatMessageModel(
            id: tempMessageID,
            roomID: room.id,
            messegeType: .text(message: messageContent),
            createdAt: Date.now.toISO8601String(),
            sender: sender,
            sendStatus: .sending
        )

        addMessage(tempMessage)
        scrollPosition = tempMessage.id
        messageText = ""

        Task { @concurrent in
            do {
                let response = try await networkService.request(
                    ChatRouter.sendMessage(roomID: room.id, content: messageContent, files: []),
                    responseType: ChatMessageResponseDTO.self
                )

                await MainActor.run {
                    let newID = response.chatID ?? tempMessageID
                    updateMessageID(from: tempMessageID, to: newID)
                    updateMessageStatus(messageID: newID, status: .sent)

                    // Realm에 메시지 저장 (updatedAt 자동 갱신됨)
                    if let sentMessage = messages.first(where: { $0.id == newID }) {
                        messageRepository.saveMessage(sentMessage)
                    }
                }
            } catch {
                print("텍스트 전송 실패: \(error)")
                await updateMessageStatus(messageID: tempMessageID, status: .failed)
            }
        }
    }

    private func sendMessageWithImages() {
        guard let room else { return }

        let tempLocalURLs = selectedImageURLs
        let messageContent = messageText
        let tempMessageID = UUID().uuidString

        // 현재 사용자 정보를 participants에서 조회
        let sender = room.participants.first(where: { $0.id == currentUserID })
                     ?? ChatUserModel(id: currentUserID, nick: "나", profileImage: nil)

        let tempMessage = ChatMessageModel(
            id: tempMessageID,
            roomID: room.id,
            messegeType: messageContent.isEmpty ? .files(files: []) : .filesWithString(files: [], message: messageContent),
            createdAt: Date.now.toISO8601String(),
            sender: sender,
            sendStatus: .sending
        )

        addMessage(tempMessage)
        scrollPosition = tempMessage.id

        // 로컬 이미지 미리 표시
        messageText = ""
        selectedImageURLs.removeAll()

        Task { @concurrent in
            do {
                // 1. 이미지 업로드
                let uploadRequest = ImageUploadRequestDTO(fileURLs: tempLocalURLs)
                let uploadResponse = try await networkService.upload(
                    MultipartRouter.uploadChatFiles(roomID: room.id, request: uploadRequest),
                    responseType: FileUploadResponseDTO.self,
                    interceptorType: .networkWithToken,
                    progress: { progress in
                        print("업로드 진행: \(Int(progress * 100))%")
                    }
                )

                let serverImageURLs = uploadResponse.files

                // 2. 로컬 -> 서버 URL 캐시 매핑
                await cacheLocalImagesToKingfisher(
                    localURLs: tempLocalURLs,
                    serverURLs: serverImageURLs
                )

                // 3. 메시지 전송 (content + file URLs)
                let response = try await networkService.request(
                    ChatRouter.sendMessage(roomID: room.id, content: messageContent, files: serverImageURLs),
                    responseType: ChatMessageResponseDTO.self
                )

                // 4. UI 업데이트 + Realm 저장
                await MainActor.run {
                    let newID = response.chatID ?? tempMessageID
                    updateMessageID(from: tempMessageID, to: newID)
                    updateMessageFiles(messageID: newID, files: serverImageURLs)
                    updateMessageStatus(messageID: newID, status: .sent)

                    // Realm에 메시지 저장 (updatedAt 자동 갱신됨)
                    if let sentMessage = messages.first(where: { $0.id == newID }) {
                        messageRepository.saveMessage(sentMessage)
                    }
                }

                // 5. 로컬 임시 파일 삭제
                for localURL in tempLocalURLs {
                    await ImageFileManager.shared.deleteImage(at: localURL)
                }
            } catch {
                print("이미지 메시지 전송 실패: \(error)")
                await updateMessageStatus(messageID: tempMessageID, status: .failed)
            }
        }
    }
    
    private func cacheLocalImagesToKingfisher(localURLs: [String], serverURLs: [String]) async {
        guard localURLs.count == serverURLs.count else { return }
        
        for (localURLString, serverURLString) in zip(localURLs, serverURLs) {
            guard let localURL = URL(string: localURLString),
                  let imageData = try? Data(contentsOf: localURL) else {
                continue
            }
            _ = try? await imageService.store(
                imageData: imageData,
                forKey: serverURLString,
                displayMode: .original,
                cacheStrategy: .diskOnly(expiration: 7 * 3600 * 24)
            )
        }
    }

    private func addMessage(_ message: ChatMessageModel) {
        // 이전 메시지 (displayConfig 계산용)
        let previousMessage = messages.last

        messages.append(message)

        let dateString = message.createdAt.toDateKey()

        // 해당 날짜의 헤더가 있는지 확인
        let hasDateHeader = chatItems.contains { item in
            if case .dateHeader(let date, _) = item, date == dateString {
                return true
            }
            return false
        }

        // 헤더 없으면 추가
        if !hasDateHeader {
            chatItems.append(.dateHeader(date: dateString, dateFormatted: dateString.toChatSectionHeader()))
        }

        // 이전 메시지의 showTime 업데이트 (같은 분이면 시간 숨김)
        if let prevMsg = previousMessage {
            updatePreviousMessageShowTime(previousMessage: prevMsg, currentMessage: message)
        }

        // displayConfig 생성
        let config = createDisplayConfig(
            message: message,
            previousMessage: previousMessage,
            nextMessage: nil
        )
        chatItems.append(.message(config: config))
    }
}


// MARK: Update Logic
extension ChatRoomViewModel {
    private func updateMessageID(from oldID: String, to newID: String) {
        guard let messageIndex = messages.firstIndex(where: { $0.id == oldID }) else { return }
        messages[messageIndex].id = newID

        // chatItems에서 해당 메시지 찾아서 업데이트
        guard let itemIndex = chatItems.firstIndex(where: { item in
            if case .message(let config) = item, config.id == oldID {
                return true
            }
            return false
        }) else { return }

        if case .message(let oldConfig) = chatItems[itemIndex] {
            var updatedMessage = oldConfig.message
            updatedMessage.id = newID
            let newConfig = MessageDisplayConfig(
                id: newID,
                message: updatedMessage,
                showProfile: oldConfig.showProfile,
                showNickname: oldConfig.showNickname,
                showTime: oldConfig.showTime
            )
            chatItems[itemIndex] = .message(config: newConfig)
        }
    }

    private func updateMessageStatus(messageID: String, status: MessageSendStatus) {
        guard let messageIndex = messages.firstIndex(where: { $0.id == messageID }) else { return }
        messages[messageIndex].sendStatus = status

        // chatItems에서 해당 메시지 찾아서 업데이트
        guard let itemIndex = chatItems.firstIndex(where: { item in
            if case .message(let config) = item, config.id == messageID {
                return true
            }
            return false
        }) else { return }

        if case .message(let oldConfig) = chatItems[itemIndex] {
            var updatedMessage = oldConfig.message
            updatedMessage.sendStatus = status
            let newConfig = MessageDisplayConfig(
                id: oldConfig.id,
                message: updatedMessage,
                showProfile: oldConfig.showProfile,
                showNickname: oldConfig.showNickname,
                showTime: oldConfig.showTime
            )
            chatItems[itemIndex] = .message(config: newConfig)
        }
    }

    private func updateMessageFiles(messageID: String, files: [String]) {
        guard let messageIndex = messages.firstIndex(where: { $0.id == messageID }) else { return }
        messages[messageIndex].messegeType.updateFiles(files: files)

        // chatItems에서 해당 메시지 찾아서 업데이트
        guard let itemIndex = chatItems.firstIndex(where: { item in
            if case .message(let config) = item, config.id == messageID {
                return true
            }
            return false
        }) else { return }

        if case .message(let oldConfig) = chatItems[itemIndex] {
            var updatedMessage = oldConfig.message
            updatedMessage.messegeType.updateFiles(files: files)
            let newConfig = MessageDisplayConfig(
                id: oldConfig.id,
                message: updatedMessage,
                showProfile: oldConfig.showProfile,
                showNickname: oldConfig.showNickname,
                showTime: oldConfig.showTime
            )
            chatItems[itemIndex] = .message(config: newConfig)
        }
    }
}


// MARK: Retry Logic
extension ChatRoomViewModel {
    func retryMessage(_ message: ChatMessageModel) {
        // TODO: Retry
    }

    private func retryTextMessage(_ message: ChatMessageModel) {
        Task { @concurrent in
            do {
                // TODO: 서버 재전송 로직
                try await Task.sleep(nanoseconds: 500_000_000)
                await updateMessageStatus(messageID: message.id, status: .sent)
            } catch {
                print("텍스트 재전송 실패: \(error)")
                await updateMessageStatus(messageID: message.id, status: .failed)
            }
        }
    }

    private func retryImageMessage(_ message: ChatMessageModel) {
        Task { @concurrent in
            do {
                // TODO: 서버 재전송 로직
                try await Task.sleep(nanoseconds: 1_000_000_000)
                await updateMessageStatus(messageID: message.id, status: .sent)
            } catch {
                print("이미지 재전송 실패: \(error)")
                await updateMessageStatus(messageID: message.id, status: .failed)
            }
        }
    }
}


// MARK: - DisplayConfig Helpers
extension ChatRoomViewModel {
    private func createDisplayConfig(
        message: ChatMessageModel,
        previousMessage: ChatMessageModel?,
        nextMessage: ChatMessageModel?
    ) -> MessageDisplayConfig {
        let isMyMessage = message.sender.id == currentUserID
        let showProfile: Bool
        let showNickname: Bool
        let showTime: Bool

        if isMyMessage {
            showProfile = false
            showNickname = false
            showTime = shouldShowTime(current: message, next: nextMessage)
        } else {
            showProfile = shouldShowProfile(current: message, previous: previousMessage)
            showNickname = showProfile
            showTime = shouldShowTime(current: message, next: nextMessage)
        }

        return MessageDisplayConfig(
            id: message.id,
            message: message,
            showProfile: showProfile,
            showNickname: showNickname,
            showTime: showTime
        )
    }

    private func shouldShowProfile(
        current: ChatMessageModel,
        previous: ChatMessageModel?
    ) -> Bool {
        
        guard let previous else { return true }
        
        if previous.sender.id == currentUserID {
            return true
        }
        
        if previous.sender.id != current.sender.id {
            return true
        }
        
        if !isSameMinute(previous.createdAt, current.createdAt) {
            return true
        }

        return false
    }

    private func shouldShowTime(
        current: ChatMessageModel,
        next: ChatMessageModel?
    ) -> Bool {
        guard let next else { return true }
        if next.sender.id != current.sender.id {
            return true
        }
        if !isSameMinute(current.createdAt, next.createdAt) {
            return true
        }

        return false
    }

    private func isSameMinute(_ time1: String, _ time2: String) -> Bool {
        guard let date1 = time1.toDate(),
              let date2 = time2.toDate() else {
            return false
        }

        let calendar = Calendar.current
        let components1 = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date1)
        let components2 = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date2)

        return components1.year == components2.year &&
               components1.month == components2.month &&
               components1.day == components2.day &&
               components1.hour == components2.hour &&
               components1.minute == components2.minute
    }

    /// 새 메시지 추가 시 이전 메시지의 showTime 업데이트
    private func updatePreviousMessageShowTime(previousMessage: ChatMessageModel, currentMessage: ChatMessageModel) {
        guard let itemIndex = chatItems.lastIndex(where: { item in
            if case .message(let config) = item, config.id == previousMessage.id {
                return true
            }
            return false
        }) else { return }

        if case .message(let oldConfig) = chatItems[itemIndex] {
            let newShowTime = shouldShowTime(current: previousMessage, next: currentMessage)
            if oldConfig.showTime != newShowTime {
                let newConfig = MessageDisplayConfig(
                    id: oldConfig.id,
                    message: oldConfig.message,
                    showProfile: oldConfig.showProfile,
                    showNickname: oldConfig.showNickname,
                    showTime: newShowTime
                )
                chatItems[itemIndex] = .message(config: newConfig)
            }
        }
    }
}


// MARK: - WebSocket
extension ChatRoomViewModel {

    func connectWebSocket() {
        guard let room else { return }

        // 기존 Task 취소
        connectionTask?.cancel()
        messageTask?.cancel()

        // 초기 상태 설정
        isWebSocketConnected = false

        // 새 연결 준비 (기존 스트림 리셋)
        webSocketManager.prepareNewConnection()

        // 새로운 Task 생성 및 저장 (리셋된 스트림에서 새로 생성됨)
        connectionTask = Task { @MainActor in
            for await isConnected in webSocketManager.connectionStates {
                print(" Connection state changed: \(isConnected)")
                self.isWebSocketConnected = isConnected
                print("isWebSocketConnected updated: \(self.isWebSocketConnected)")

                // WebSocket 연결 완료 시 서버에서 메시지 fetch & 큐 처리
                if isConnected {
                    await self.fetchAndSync()
                }
            }
        }

        messageTask = Task { @MainActor in
            for await messageDTO in webSocketManager.messages {
                if isRealmSynced {
                    handleWebSocketMessage(messageDTO)
                } else {
                    messageQueue.append(messageDTO)
                }
            }
        }

        // 스트림 구독 후 연결 시작
        webSocketManager.connect(roomID: room.id)
    }
    /// WebSocket 메시지 처리 (즉시 처리)
    private func handleWebSocketMessage(_ messageDTO: ChatMessageResponseDTO) {
        guard let room else { return }

        let message = messageDTO.toVM()

        // 내가 보낸 메시지가 아닐 때만 추가
        if message.sender.id != currentUserID {
            addMessage(message)
            messageRepository.saveMessage(message)
            roomRepository.updateRoomTime(roomID: room.id, updatedAt: Date())
        }
    }

    /// WebSocket 연결 해제
    func disconnectWebSocket() {
        connectionTask?.cancel()
        messageTask?.cancel()
        connectionTask = nil
        messageTask = nil
        webSocketManager.disconnect()
        isWebSocketConnected = false
    }
}
