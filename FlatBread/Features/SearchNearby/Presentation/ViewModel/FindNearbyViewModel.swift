//
//  FindNearbyViewModel.swift
//  FlatBread
//
//  Created by 김민성 on 11/29/25.
//

import Combine
import Foundation
import SwiftUI

final class FindNearbyViewModel: ObservableObject {
    
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    
    @Published var myProfile: FindNearbyMyProfileUIModel? = nil
    @Published var chatRoom: ChatRoomModel? = nil
    @Published var alertMessage: String? = nil
    @Published var showAlert: Bool = false
    
    init() {
        fetchMyProfile()
    }
    
    func fetchMyProfile() {
        
        let router = UserRouter.getMeProfile
        Task {
            do {
                self.myProfile = try await networkService
                    .request(router, responseType: UserProfileResponseDTO.self)
                    .asFindNearByUIModel
            } catch {
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
    
    func fetchChatModel(opponent_id: String) {
        Task {
            do {
                let response = try await networkService.request(
                    ChatRouter.makeChatRoom(opponent_id: opponent_id),
                    responseType: ChatResponseDTO.self
                )
                self.chatRoom = response.toVM()
            } catch {
                alertMessage = "채팅방 생성에 실패했습니다."
                showAlert = true
                self.chatRoom = nil
            }
        }
    }
    
}
