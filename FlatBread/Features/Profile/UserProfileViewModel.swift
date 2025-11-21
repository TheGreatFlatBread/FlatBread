//
//  UserProfileViewModel.swift
//  FlatBread
//
//  Created by hwan on 11/21/25.
//

import Foundation
import Combine

@MainActor
final class UserProfileViewModel: ObservableObject {

    @Published var userProfile: UserProfileResponseDTO?
    @Published var userPosts: [PostUIModel] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingPosts: Bool = false
    @Published var isLoadingMorePosts: Bool = false
    @Published var errorMessage: String?
    @Published var showingAlert: Bool = false

    let userID: String
    let moimId: String?
    let isCurrentUser: Bool

    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    private var nextCursor: String = ""
    private let pageLimit = "5"

    var hasMorePosts: Bool {
        !nextCursor.isEmpty
    }

    init(userID: String, moimId: String? = nil, isCurrentUser: Bool = false) {
        self.userID = userID
        self.moimId = moimId
        self.isCurrentUser = isCurrentUser
    }

    func fetchUserProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            let router = isCurrentUser
                ? UserRouter.getMeProfile
                : UserRouter.getOtherUserProfile(userID: userID)

            let response = try await networkService.request(
                router,
                responseType: UserProfileResponseDTO.self,
                interceptorType: .networkWithToken
            )
            userProfile = response
        } catch {
            errorMessage = error.localizedDescription
            showingAlert = true
        }

        isLoading = false
    }

    func fetchUserPosts() async {
        guard let moimId else { return }

        isLoadingPosts = true
        nextCursor = ""
        userPosts = []

        do {
            let response = try await networkService.request(
                PostRouter.getUserPostList(
                    userID: userID,
                    next: "",
                    limit: pageLimit,
                    category: [moimId]
                ),
                responseType: PostListResponseDTO.self,
                interceptorType: .networkWithToken
            )
            userPosts = response.data.compactMap {
                PostMapper.toPostUIModel(from: $0, currentUserId: userID)
            }
            nextCursor = response.next_cursor
        } catch {
            #if DEBUG
            print("게시물 로드 실패: \(error.localizedDescription)")
            #endif
        }

        isLoadingPosts = false
    }

    func loadMorePosts() async {
        guard let moimId, hasMorePosts, !isLoadingMorePosts else { return }

        isLoadingMorePosts = true

        do {
            let response = try await networkService.request(
                PostRouter.getUserPostList(
                    userID: userID,
                    next: nextCursor,
                    limit: pageLimit,
                    category: [moimId]
                ),
                responseType: PostListResponseDTO.self,
                interceptorType: .networkWithToken
            )
            let newPosts = response.data.compactMap {
                PostMapper.toPostUIModel(from: $0, currentUserId: userID)
            }
            userPosts.append(contentsOf: newPosts)
            nextCursor = response.next_cursor
        } catch {
            #if DEBUG
            print("추가 게시물 로드 실패: \(error.localizedDescription)")
            #endif
        }

        isLoadingMorePosts = false
    }

    func startChat() {
        // TODO: 1:1 채팅방 생성 또는 기존 채팅방으로 이동
        // 채팅 기능 구현 시 연결
    }
}
