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
    let room: ChatRoomModel
    let currentUserID: String

    @Published private(set) var messages: [ChatMessageModel] = []
    @Published var messageText: String = ""
    @Published var isLoadingMore: Bool = false
    @Published var scrollPosition: String = ""
    @Published var groupedMessages: [ChatMessageSection] = []
    @Published var selectedImageURLs: [String] = []  // temp file URLs

    private var currentPageOffset: Int = 0
    private var cursorDate: String?

    private let networkService: AsyncNetworkService
    
    init(room: ChatRoomModel, currentUserID: String) {
        self.room = room
        self.currentUserID = currentUserID
        self.networkService = NetworkServiceFactory.shared.makeNetworkService()
    }

    func sendMessage() {
        guard !messageText.isEmpty || !selectedImageURLs.isEmpty else { return }
        if !selectedImageURLs.isEmpty {
            sendMessageWithImages()
        } else {
            sendTextOnly()
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
        guard !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let cursor = messages.first?.createdAt ?? Date.now.toISO8601String()

            let response = try await networkService.request(
                ChatRouter.fetchChatMessgeList(roomID: self.room.id, cursorDate: cursor),
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
            // TODO: 에러 타입별 처리 (네트워크 에러, 인증 에러 등)
        }
    }
    
}


// MARK: Send Logic
extension ChatRoomViewModel {
    private func sendTextOnly() {
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
                // TODO: 서버 전송 로직 WebSocket 사용해서 Send
                // let response = try await NetworkService.shared.request(...)
                // Mock: 0.5초 대기 후 전송 완료
                try await Task.sleep(nanoseconds: 500_000_000)
                await updateMessageStatus(messageID: tempMessageID, status: .sent)
            } catch {
                print("텍스트 전송 실패: \(error)")
                await updateMessageStatus(messageID: tempMessageID, status: .failed)
            }
        }
    }

    private func sendMessageWithImages() {
        let tempLocalURLs = selectedImageURLs  // 이미 temp file로 저장된 상태
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

        messageText = ""
        selectedImageURLs.removeAll()

        Task { @concurrent in
            do {
//              temp file은 이미 저장되어 있음!
                await updateMessageFiles(messageID: tempMessageID, files: tempLocalURLs)

//              let localFileURLs = tempLocalURLs.compactMap { URL(string: $0) }
//              let uploadRequest = ImageUploadRequestDTO(fileURLs: localFileURLs)
//              let router = MultipartRouter.uploadChatFiles(
//                  roomID: self.room.id,
//                  request: uploadRequest
//              )
//
//              let uploadResponse = try await networkService.upload(
//                  router,
//                  responseType: FileUploadResponseDTO.self,
//                  interceptorType: .networkWithToken,
//                  progress: { progress in
//                      print("업로드 진행: \(Int(progress * 100))%")
//                  }
//              )
//
//              let serverImageURLs = uploadResponse.files
                let tempServerURLs = tempLocalURLs.enumerated().map { value in "http://example\(value.offset).com" }
                await cacheLocalImagesToKingfisher(
                    localURLs: tempLocalURLs,
                    serverURLs:  tempServerURLs// TODO: server url 로 변경
                )
//
                await updateMessageFiles(messageID: tempMessageID, files: tempServerURLs)
                await updateMessageStatus(messageID: tempMessageID, status: .sent)
                
                // await ImageFileManager.shared.deleteImages(at: tempLocalURLs)
                // TODO: Image URL 와 Text를 같이 Websocket으로 전달 해야함
            } catch {
                await updateMessageStatus(messageID: tempMessageID, status: .failed)
                // 실패 시에는 temp file 유지 (이미지 표시 + Retry 가능)
                // 앱 시작 시 오래된 파일 자동 정리됨
            }
        }
    }
    
    private func cacheLocalImagesToKingfisher(localURLs: [String], serverURLs: [String]) async {
        guard localURLs.count == serverURLs.count else { return }
        for (localURLString, serverURLString) in zip(localURLs, serverURLs) {
            guard let localURL = URL(string: localURLString),
                  let imageData = try? Data(contentsOf: localURL),
                  let image = UIImage(data: imageData) else {
                continue
            }
            
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                KingfisherManager.shared.cache.store(
                    image,  // ← UIImage로 저장!
                    forKey: serverURLString,
                    options: KingfisherParsedOptionsInfo([
                        .diskCacheExpiration(.days(7))
                    ])
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
