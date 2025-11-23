//
//  PostListViewModel.swift
//  FlatBread
//
//  Created by hwan on 11/16/25.
//

import Foundation
import Combine

@MainActor
final class PostListViewModel: ObservableObject {
    
    @Published var moim: TempPostMoimModel?
    @Published var posts: [PostUIModel] = []
    @Published var selectedTab: MoimTab = .posts
    @Published var selectedCategory: PostType = .all
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentUserNick: String = ""
    
    private let networkService: AsyncNetworkService = NetworkServiceFactory.shared.makeNetworkService()
    private(set) var currentUserId: String = ""
    private(set) var moimId: String
    private var postIdSet: Set<String> = []
    
    private var cursors: [PostType: String] = [
        .all: "", .schedule: "",
        .greeting: "", .free: ""
    ]
    private var hasMore: [PostType: Bool] = [
        .all: true, .schedule: true,
        .greeting: true, .free: true
    ]
    
    var filteredPosts: [PostUIModel] {
        switch selectedCategory {
        case .all: return posts
        case .free: return posts.filter { $0.postType == .free }
        case .greeting: return posts.filter { $0.postType == .greeting }
        case .schedule: return posts.filter { $0.postType == .schedule }
        }
    }
    
    var shouldShowPagination: Bool {
        switch selectedTab {
        case .posts:
            return hasMore[selectedCategory] == true
        case .schedule:
            return hasMore[.schedule] == true
        case .members:
            return false
        }
    }
    
    var schedules: [ScheduleUIModel] {
        posts.compactMap { $0.schedule }
    }
    
    var members: [MemberUIModel] = []
    
    var isMember: Bool {
        guard let moim else { return false }
        return moim.memberIds.contains(currentUserId)
    }
    
    var isLeader: Bool {
        guard let moim else { return false }
        return moim.creator.id == currentUserId
    }
    
    init(moim: TempPostMoimModel) {
        self.moimId = moim.id
        self.moim = moim
    }
    
    init(moimId: String) {
        self.moimId = moimId
    }
    
    func loadInitialData() async {
        isLoading = true
        await loadCurreqntUserId()
        if let memberIds = await fetchMoimData() {
            await fetchLoadMember(memberIds: memberIds)
        }
        isLoading = false
        posts = await fetchPosts()
    }
    
    private func loadCurreqntUserId() async {
        do {
            let profile = try await networkService.request(
                UserRouter.getMeProfile,
                responseType: UserProfileResponseDTO.self
            )
            currentUserId = profile.userID ?? ""
            currentUserNick = profile.nick ?? ""
        } catch {
            print("Failed to load current user ID: \(error)")
        }
    }
    
    func fetchLoadMember(memberIds: [String]) async {
        guard let moim else { return }
        
        let leader = MemberUIModel(
            id: moim.creator.id,
            name: moim.creator.name,
            profileImageURL: moim.creator.profileImageURL,
            bio: nil,
            isLeader: true,
            joinedAt: moim.createdAt
        )
        
        let memberIdsWithoutLeader = memberIds.filter { $0 != moim.creator.id }
        let fetchedMembers = await fetchMembersInParallel(memberIds: memberIdsWithoutLeader)
        members = [leader] + fetchedMembers.sorted { $0.joinedAt < $1.joinedAt }
    }

    private func fetchMembersInParallel(memberIds: [String]) async -> [MemberUIModel] {
        await withTaskGroup(of: MemberUIModel?.self) { group in
            for memberId in memberIds {
                group.addTask {
                    await self.fetchSingleMember(userId: memberId)
                }
            }

            var members: [MemberUIModel] = []
            for await member in group {
                if let member {
                    members.append(member)
                }
            }
            return members
        }
    }

    private func fetchSingleMember(userId: String) async -> MemberUIModel? {
        if let cachedUser = await UserCache.shared.get(userId) {
            return mapToMemberUIModel(cachedUser, isLeader: false)
        }

        do {
            let userProfile = try await networkService.request(
                UserRouter.getOtherUserProfile(userID: userId),
                responseType: UserProfileResponseDTO.self
            )
            
            await UserCache.shared.set(userId, user: userProfile)

            return mapToMemberUIModel(userProfile, isLeader: false)
        } catch {
            print("Failed to fetch member \(userId): \(error)")
            return nil
        }
    }

    private func mapToMemberUIModel(_ user: UserProfileResponseDTO, isLeader: Bool) -> MemberUIModel {
        MemberUIModel(
            id: user.userID ?? "",
            name: user.nick ?? "알 수 없음",
            profileImageURL: user.profileImage,
            bio: user.info1,
            isLeader: isLeader,
            joinedAt: Date.now
        )
    }
    
    func fetchMoimData() async -> [String]? {
        do {
            let response = try await networkService.request(
                PostRouter.getPost(postID: moimId),
                responseType: PostResponseDTO.self
            )
            
            if let moimModel = PostMapper.toTempMoimModel(from: response) {
                let fee = response.price ?? moimModel.membershipFee
                let adjusted = TempPostMoimModel(
                    id: moimModel.id,
                    name: moimModel.name,
                    category: moimModel.category,
                    description: moimModel.description,
                    location: moimModel.location,
                    imageURLs: moimModel.imageURLs,
                    memberCount: moimModel.memberCount,
                    maxMembers: moimModel.maxMembers,
                    hashtags: moimModel.hashtags,
                    createdAt: moimModel.createdAt,
                    creator: moimModel.creator,
                    memberIds: moimModel.memberIds,
                    membershipFee: fee
                )
                moim = adjusted
                return adjusted.memberIds
            }
            return nil
        } catch {
            errorMessage = "모임 정보를 불러오는데 실패했습니다."
            return nil
        }
    }
    
    func fetchPosts() async -> [PostUIModel] {
        let category = selectedTab == .schedule ? PostType.schedule : selectedCategory

        guard hasMore[category] == true else {
            return posts
        }
        isLoading = true
        defer { isLoading = false }

        do {
            let cursor = cursors[category] ?? ""
            let response = try await requestPosts(category: category, cursor: cursor)
            
            cursors[category] = response.next_cursor
            hasMore[category] = response.next_cursor != "0"

            let newPosts = response.data.compactMap {
                PostMapper.toPostUIModel(from: $0, currentUserId: currentUserId)
            }

            let unique = newPosts.filter { !postIdSet.contains($0.id) }
            unique.forEach { postIdSet.insert($0.id) }

            return posts + unique
        } catch {
            errorMessage = "게시물을 불러오는데 실패했습니다."
            return posts
        }
    }

    func toggleLike(for post: PostUIModel) async {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }

        let newLikeStatus = !posts[index].isLiked

        // Optimistic update
        posts[index].isLiked = newLikeStatus
        posts[index].likeCount += newLikeStatus ? 1 : -1

        do {
            _ = try await networkService.request(
                PostRouter.togglePostLikeV1(postID: post.id, like_status: newLikeStatus),
                responseType: LikeResponseDTO.self
            )
        } catch {
            // Rollback on failure
            posts[index].isLiked = !newLikeStatus
            posts[index].likeCount += newLikeStatus ? -1 : 1
            errorMessage = "좋아요 처리에 실패했습니다."
        }
    }

    func toggleBookmark(for post: PostUIModel) {
        // TODO: 북마크 토글 API
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].isBookmarked.toggle()
    }

    func selectCategory(_ category: PostType) {
        selectedCategory = category
    }
    
    func loadMore() async {
        guard !isLoading else { return }
        isLoading = true
        if selectedTab != .members {
            posts = await fetchPosts()
        }
        isLoading = false
    }
    
    func incrementCommentCount(for postId: String) {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return }
        posts[index].commentCount += 1
    }

    func refreshPosts() async {
        cursors = [.all: "", .schedule: "", .greeting: "", .free: ""]
        hasMore = [.all: true, .schedule: true, .greeting: true, .free: true]
        postIdSet = []
        
        posts = await fetchPosts()
    }

    func toggleMoimMembership() async {
        guard let moim else { return }
        isLoading = true
        defer { isLoading = false }
        let newStatus = !isMember
        do {
            _ = try await networkService.request(
                PostRouter.togglePostLikeV2(postID: moim.id, like_status: newStatus),
                responseType: LikeResponseDTO.self
            )
            _ = await fetchMoimData()
        } catch {
            errorMessage = "모임 \(newStatus ? "가입" : "탈퇴")에 실패했습니다."
        }
    }
    
    func makePaymentInputForMoimJoin() -> IamportPaymentInput? {
        guard let moim else { return nil }
        let postId = moim.id
        let title = moim.name
        let price = moim.membershipFee
        let buyerName = currentUserNick
        return IamportPaymentInput(postId: postId, price: price, title: title, buyerName: buyerName)
    }
    
    func deletePost(_ postId: String) async -> Bool {
        do {
            _ = try await networkService.request(
                PostRouter.deletePost(postID: postId),
                responseType: EmptyEntity.self
            )
            posts.removeAll { $0.id == postId }
            return true
        } catch {
            errorMessage = "게시물 삭제에 실패했습니다."
            return false
        }
    }

    func isMyPost(_ post: PostUIModel) -> Bool {
        post.author.id == currentUserId
    }

    func addNewPost(_ response: PostResponseDTO) {
        guard let newPost = PostMapper.toPostUIModel(from: response, currentUserId: currentUserId) else {
            return
        }

        guard !postIdSet.contains(newPost.id) else { return }

        posts.insert(newPost, at: 0)
        postIdSet.insert(newPost.id)
    }

    func updateExistingPost(_ response: PostResponseDTO) {
        guard let updatedPost = PostMapper.toPostUIModel(from: response, currentUserId: currentUserId) else {
            return
        }

        if let index = posts.firstIndex(where: { $0.id == updatedPost.id }) {
            posts[index] = updatedPost
        }
    }

    private func requestPosts(category: PostType, cursor: String) async throws -> PostListResponseDTO {
        switch category {
        case .all:
            return try await networkService.request(
                PostRouter.getPostList(
                    next: cursor,
                    limit: "20",
                    category: [moimId]
                ),
                responseType: PostListResponseDTO.self
            )
            
        case .schedule, .greeting, .free:
            return try await networkService.request(
                PostRouter.searchHashTagList(
                    next: cursor,
                    limit: "20",
                    category: [moimId],
                    hashTag: category.categoryHashtag
                ),
                responseType: PostListResponseDTO.self
            )
        }
    }
}

