//
//  ChatViewMode.swift
//  FlatBread
//
//  Created by hwan on 11/12/25.
//

import Foundation
import Combine

final class MoimChatListViewModel: ObservableObject {
    @Published var chatRooms: [ChatRoomModel] = []
    @Published var chatError: ChatFeatureError?

    private let networkService: AsyncNetworkService
    private let roomRepository = ChatRoomRepository.shared
    private var isSyncing = false
    private let currentUserID: String

    init(currentUserID: String, networkService: AsyncNetworkService = NetworkServiceFactory.shared.makeNetworkService()) {
        self.currentUserID = currentUserID
        self.networkService = networkService
    }

    func loadChatRooms() async {
        let cachedRooms = roomRepository.getAllRooms(currentUserID: currentUserID)
        if !cachedRooms.isEmpty {
            await MainActor.run {
                self.chatRooms = cachedRooms
            }
        }
        await fetchChatList()
    }
    
    func fetchChatList() async {
        guard !isSyncing else {
            return
        }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let response = try await networkService.request(
                ChatRouter.fetchChatRoomList,
                responseType: ChatListResponseDTO.self,
                interceptorType: .networkWithToken
            )

            let rooms = response.data.map { $0.toVM() }

            roomRepository.saveRooms(rooms)

            let hasStructuralChange = await MainActor.run {
                rooms.count != chatRooms.count ||
                zip(rooms, chatRooms).contains {
                    $0.0.id != $0.1.id
                }
            }

            if hasStructuralChange {
                await MainActor.run {
                    self.chatRooms = rooms
                }
            }

            let updates = await withTaskGroup(of: (String, ChatMessageModel?, Int).self, returning: [(String, ChatMessageModel?, Int)].self)
            { @concurrent group in
                for room in rooms {
                    group.addTask {
                        let localLastMessage = await ChatMessageRepository.shared.getLastMessage(
                            roomID: room.id,
                            participants: room.participants
                        )
                        if let serverLastChat = room.lastChat,
                           let localLast = localLastMessage,
                           serverLastChat.id != localLast.id {
                            await ChatSyncManager.shared.syncMessages(
                                roomID: room.id,
                                participants: room.participants,
                                createdAt: room.createdAt,
                                networkService: self.networkService
                            )
                        }
                        let unreadCount = await self.roomRepository.getUnreadCount(roomID: room.id, currentUserID: self.currentUserID)
                        return (room.id, room.lastChat, unreadCount)
                    }
                }
                var results: [(String, ChatMessageModel?, Int)] = []
                for await result in group {
                    results.append(result)
                }
                return results
            }
            
            await MainActor.run {
                for (roomID, lastChat, unread) in updates {
                    guard let index = self.chatRooms.firstIndex(where: { $0.id == roomID }) else { continue }

                    if self.chatRooms[index].lastChat?.id != lastChat?.id {
                        self.chatRooms[index].lastChat = lastChat
                    }

                    if self.chatRooms[index].unreadCount != unread {
                        self.chatRooms[index].unreadCount = unread
                    }
                }
            }
        } catch {
            switch error {
            case .apiError(let apiError):
                switch apiError {
                case .expiredAccessToken, .failedReissueToken:
                    chatError = .loginNeeded
                default:
                    chatError = .serverError
                }
            default:
                chatError = .failedNetwork
            }
        }
    }
    
    func openChat() async {
        
    }
}
