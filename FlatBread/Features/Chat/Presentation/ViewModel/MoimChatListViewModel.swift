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
    
    init(networkService: AsyncNetworkService = NetworkServiceFactory.shared.makeNetworkService()) {
        self.networkService = networkService
    }

    func fetchChatList() async {
        do {
            let response = try await networkService.request(
                ChatRouter.fetchChatRoomList,
                responseType: ChatListResponseDTO.self,
                interceptorType: .networkWithToken
            )
            self.chatRooms = response.data.map { $0.toVM() }
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
