//
//  ChatRoomDetailViewModel.swift
//  FlatBread
//
//  Created by hwan on 11/14/25.
//

import SwiftUI
import Combine
import Kingfisher

@MainActor
final class ChatRoomViewModel: ObservableObject {
    private(set) var room: ChatRoomModel?
    let currentUserID: String

    // opponent 정보 (새 채팅방 생성 시 사용)
    private let opponentID: String?
    private let opponentNick: String?
    private let opponentProfileImage: String?

    @Published private(set) var messages: [ChatMessageModel] = []
    @Published var messageText: String = ""
    @Published var isLoadingMore: Bool = false
    @Published var scrollPosition: String = ""
    @Published var groupedMessages: [ChatMessageSection] = []
    @Published var selectedImageURLs: [String] = []  // temp file URLs
    @Published var isCreatingRoom: Bool = false

    private var currentPageOffset: Int = 0
    private var cursorDate: String?

    private let networkService: AsyncNetworkService

    var displayTitle: String {
        room?.participants.first { $0.id != currentUserID }?.nick
            ?? opponentNick
            ?? "채팅방"
    }

    var isEmpty: Bool {
        messages.isEmpty && groupedMessages.isEmpty
    }

    /// 기존 채팅방으로 초기화
    init(room: ChatRoomModel, currentUserID: String) {
        self.room = room
        self.currentUserID = currentUserID
        self.opponentID = nil
        self.opponentNick = nil
        self.opponentProfileImage = nil
        self.networkService = NetworkServiceFactory.shared.makeNetworkService()
    }

    /// 새 채팅 시작 (opponent 정보로 초기화, 첫 메시지 전송 시 room 생성)
    init(opponentID: String, opponentNick: String, opponentProfileImage: String?, currentUserID: String) {
        self.room = nil
        self.currentUserID = currentUserID
        self.opponentID = opponentID
        self.opponentNick = opponentNick
        self.opponentProfileImage = opponentProfileImage
        self.networkService = NetworkServiceFactory.shared.makeNetworkService()
    }

    func sendMessage() {
        guard !messageText.isEmpty || !selectedImageURLs.isEmpty else { return }

        // room이 없으면 먼저 생성
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
                // 실패 시 입력 복원
                messageText = pendingText
                selectedImageURLs = pendingImages
                print("채팅방 생성 실패: \(error)")
            }
        }
    }

    func removeImage(at index: Int) {
        guard index < selectedImageURLs.count else { return }
        let urlToRemove = selectedImageURLs[index]
        selectedImageURLs.remove(at: index)
        ImageFileManager.shared.deleteImage(at: urlToRemove)
    }
    
    func loadMoreMessages() async {
        await fetchChatMessageList()
    }
    
    func fetchChatMessageList() async {
        guard let room, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let cursor = messages.first?.createdAt ?? Date.now.toISO8601String()

            let response = try await networkService.request(
                ChatRouter.fetchChatMessgeList(roomID: room.id, cursorDate: cursor),
                responseType: ChatMessageListResponseDTO.self,
                interceptorType: .networkWithToken
            )

            let moreMessages = response.data.map { $0.toVM() }

            if !moreMessages.isEmpty {
                cursorDate = moreMessages.first?.createdAt
                insertMessages(moreMessages, at: 0)
            }
        } catch {
            print("채팅 메시지 로드 실패: \(error)")
        }
    }
    
}


// MARK: Send Logic
extension ChatRoomViewModel {
    private func sendTextOnly() {
        guard let room else { return }

        let messageContent = messageText
        let tempMessageID = UUID().uuidString

        let tempMessage = ChatMessageModel(
            id: tempMessageID,
            roomID: room.id,
            messegeType: .text(message: messageContent),
            createdAt: Date.now.toString(),
            sender: ChatUserModel(
                id: currentUserID,
                nick: "나",
                profileImage: nil
            ),
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
                    updateMessageID(from: tempMessageID, to: response.chatID ?? tempMessageID)
                    updateMessageStatus(messageID: response.chatID ?? tempMessageID, status: .sent)
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

        let tempMessage = ChatMessageModel(
            id: tempMessageID,
            roomID: room.id,
            messegeType: messageContent.isEmpty ? .files(files: []) : .filesWithString(files: [], message: messageContent),
            createdAt: Date.now.toString(),
            sender: ChatUserModel(
                id: currentUserID,
                nick: "나",
                profileImage: nil
            ),
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

                // 4. UI 업데이트
                await MainActor.run {
                    updateMessageID(from: tempMessageID, to: response.chatID ?? tempMessageID)
                    updateMessageFiles(messageID: response.chatID ?? tempMessageID, files: serverImageURLs)
                    updateMessageStatus(messageID: response.chatID ?? tempMessageID, status: .sent)
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

            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                KingfisherManager.shared.cache.storeToDisk(
                    imageData,
                    forKey: serverURLString,
                    expiration: .never
                ) { _ in
                    continuation.resume()
                }
            }
        }
    }

    private func addMessage(_ message: ChatMessageModel) {
        messages.append(message)

        let dateString = message.createdAt.toDateKey()

        if let sectionIndex = groupedMessages.firstIndex(where: { $0.date == dateString }) {
            let updatedSection = groupedMessages[sectionIndex]
            var updatedMessages = updatedSection.messages
            updatedMessages.append(message)

            groupedMessages[sectionIndex] = ChatMessageSection.create(
                date: updatedSection.date,
                dateFormatted: updatedSection.dateFormatted,
                messages: updatedMessages,
                currentUserID: currentUserID
            )
        } else {
            let newSection = ChatMessageSection.create(
                date: dateString,
                dateFormatted: dateString.toChatSectionHeader(),
                messages: [message],
                currentUserID: currentUserID
            )
            groupedMessages.append(newSection)
        }
    }
    
    private func insertMessages(_ newMessages: [ChatMessageModel], at index: Int) {
        messages.insert(contentsOf: newMessages, at: index)

        let newGrouped = Dictionary(grouping: newMessages) { message -> String in
            message.createdAt.toDateKey()
        }

        for (dateString, newMessagesInDate) in newGrouped {
            if let sectionIndex = groupedMessages.firstIndex(where: { $0.date == dateString }) {
                let updatedSection = groupedMessages[sectionIndex]
                var updatedMessages = updatedSection.messages
                let sortedNewMessages = newMessagesInDate.sorted { $0.createdAt < $1.createdAt }
                updatedMessages.insert(contentsOf: sortedNewMessages, at: 0)
                groupedMessages[sectionIndex] = ChatMessageSection.create(
                    date: updatedSection.date,
                    dateFormatted: updatedSection.dateFormatted,
                    messages: updatedMessages,
                    currentUserID: currentUserID
                )
            } else {
                let newSection = ChatMessageSection.create(
                    date: dateString,
                    dateFormatted: dateString.toChatSectionHeader(),
                    messages: newMessagesInDate.sorted { $0.createdAt < $1.createdAt },
                    currentUserID: currentUserID
                )
                groupedMessages.insert(newSection, at: 0)
            }
        }
    }
}


// MARK: Update Logic
extension ChatRoomViewModel {
    @MainActor
    private func updateMessageID(from oldID: String, to newID: String) {
        guard let messageIndex = messages.firstIndex(where: { $0.id == oldID }) else { return }
        messages[messageIndex].id = newID

        let dateKey = messages[messageIndex].createdAt.toDateKey()
        guard let sectionIndex = groupedMessages.firstIndex(where: { $0.date == dateKey }) else { return }

        var section = groupedMessages[sectionIndex]
        guard let sectionMsgIndex = section.messages.firstIndex(where: { $0.id == oldID }) else { return }

        section.messages[sectionMsgIndex].id = newID

        groupedMessages[sectionIndex] = ChatMessageSection.create(
            date: section.date,
            dateFormatted: section.dateFormatted,
            messages: section.messages,
            currentUserID: currentUserID
        )
    }

    @MainActor
    private func updateMessageStatus(messageID: String, status: MessageSendStatus) {
        guard let messageIndex = messages.firstIndex(where: { $0.id == messageID }) else { return }
        messages[messageIndex].sendStatus = status
        let updatedMessage = messages[messageIndex]
        
        let dateKey = updatedMessage.createdAt.toDateKey()
        guard let sectionIndex = groupedMessages.firstIndex(where: { $0.date == dateKey }) else { return }
        
        var section = groupedMessages[sectionIndex]
        guard let sectionMessageIndex = section.messages.firstIndex(where: { $0.id == messageID }) else { return }
        
        section.messages[sectionMessageIndex].sendStatus = status
        
        groupedMessages[sectionIndex] = ChatMessageSection.create(
            date: section.date,
            dateFormatted: section.dateFormatted,
            messages: section.messages,
            currentUserID: currentUserID
        )
    }

    @MainActor
    private func updateMessageFiles(messageID: String, files: [String]) {
        guard let messageIndex = messages.firstIndex(where: { $0.id == messageID }) else { return }
        var updatedMessage = messages[messageIndex]

        updatedMessage.messegeType.updateFiles(files: files)

        messages[messageIndex] = updatedMessage

        let dateKey = updatedMessage.createdAt.toDateKey()
        guard let sectionIndex = groupedMessages.firstIndex(where: { $0.date == dateKey }) else { return }

        var section = groupedMessages[sectionIndex]

        guard let sectionMsgIndex = section.messages.firstIndex(where: { $0.id == messageID }) else { return }

        section.messages[sectionMsgIndex] = updatedMessage

        groupedMessages[sectionIndex] = ChatMessageSection.create(
            date: section.date,
            dateFormatted: section.dateFormatted,
            messages: section.messages,
            currentUserID: currentUserID
        )
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
