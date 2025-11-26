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

    init(networkService: AsyncNetworkService = NetworkServiceFactory.shared.makeNetworkService()) {
        self.networkService = networkService
    }

    /// 최초 로드: Realm 캐시 먼저 표시 후 서버 동기화
    func loadChatRooms() async {
        // 1. Realm에서 캐시된 채팅방 로드 (빠른 표시)
        let cachedRooms = roomRepository.getAllRooms()
        if !cachedRooms.isEmpty {
            await MainActor.run {
                self.chatRooms = cachedRooms
            }
        }

        // 2. 서버에서 최신 데이터 가져와서 동기화
        await fetchChatList()
    }

    /// 서버에서 채팅방 목록 가져와서 Realm에 저장
    func fetchChatList() async {
        do {
            let response = try await networkService.request(
                ChatRouter.fetchChatRoomList,
                responseType: ChatListResponseDTO.self,
                interceptorType: .networkWithToken
            )

            let rooms = response.data.map { $0.toVM() }

            // Realm에 저장
            roomRepository.saveRooms(rooms)

            // UI 업데이트
            await MainActor.run {
                self.chatRooms = rooms
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
