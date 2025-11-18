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
    
    @Published var posts: [PostUIModel] = PostUIModel.mocks
    @Published var members: [MemberUIModel] = []
    
    var schedules: [ScheduleUIModel] {
        posts.compactMap { $0.schedule }
    }
    
    @Published var selectedTab: MoimTab = .posts
    @Published var selectedCategory: PostType = .all
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let networkService: AsyncNetworkService = NetworkServiceFactory.shared.makeNetworkService()
    private var currentUserId: String = ""
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
    
    init(moimId: String) {
        self.moimId = moimId
    }
    
    init(moim: TempPostMoimModel) {
        self.moimId = moim.id
        self.moim = moim
    }
    
    private func loadCurrentUserId() async {
        do {
            let profile = try await networkService.request(
                UserRouter.getMeProfile,
                responseType: UserProfileResponseDTO.self
            )
            currentUserId = profile.userID ?? ""
        } catch {
            print("Failed to load current user ID: \(error)")
        }
    }
    
    func loadInitialData() async {
        await loadCurrentUserId()
        await fetchMoimData()
        await fetchPosts()
    }
    
    func fetchMoimData() async {
        do {
            let response = try await networkService.request(
                PostRouter.getPost(postID: moimId),
                responseType: PostResponseDTO.self
            )
            
            if let moimModel = PostMapper.toTempMoimModel(from: response) {
                moim = moimModel
            }
        } catch {
            errorMessage = "모임 정보를 불러오는데 실패했습니다."
        }
    }
    
    func fetchPosts() async {
        let category = selectedTab == .schedule ? PostType.schedule : selectedCategory
        guard hasMore[category] == true else { return }
        
        isLoading = true
        do {
            let response: PostListResponseDTO
            
            switch category {
            case .all:
                response = try await networkService.request(
                    PostRouter.getPostList(
                        next: cursors[.all] ?? "",
                        limit: "20",
                        category: [moimId]
                    ),
                    responseType: PostListResponseDTO.self
                )
                
            case .schedule, .greeting, .free:
                response = try await networkService.request(
                    PostRouter.searchHashTagList(
                        next: cursors[category] ?? "",
                        limit: "20",
                        category: [moimId],
                        hashTag: category.categoryHashtag
                    ),
                    responseType: PostListResponseDTO.self
                )
            }
            
            cursors[category] = response.next_cursor
            hasMore[category] = response.next_cursor != "0"
            
            let newPosts = response.data.compactMap { dto in
                PostMapper.toPostUIModel(from: dto, currentUserId: currentUserId)
            }
            let uniquePosts = newPosts.filter { !postIdSet.contains($0.id) }
            uniquePosts.forEach { postIdSet.insert($0.id) }
            posts.append(contentsOf: uniquePosts)
            isLoading = false
        } catch {
            errorMessage = "게시물을 불러오는데 실패했습니다."
            isLoading = false
        }
    }
    
    
    func toggleLike(for post: PostUIModel) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        let previousState = posts[index].isLiked
        posts[index].isLiked.toggle()
        posts[index].likeCount += posts[index].isLiked ? 1 : -1
        
        Task {
            do {
                let _ = try await networkService.request(
                    PostRouter.togglePostLikeV1(postID: post.id, like_status: posts[index].isLiked),
                    responseType: LikeResponseDTO.self
                )
            } catch {
                posts[index].isLiked = previousState
                posts[index].likeCount += previousState ? 1 : -1
                errorMessage = "좋아요 처리에 실패했습니다."
            }
        }
    }
    
    func selectCategory(_ category: PostType) {
        selectedCategory = category
    }
    
    func toggleBookmark(for post: PostUIModel) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        let previousState = posts[index].isBookmarked
        posts[index].isBookmarked.toggle()
        
        Task {
            do {
                let _ = try await networkService.request(
                    PostRouter.togglePostLikeV2(postID: post.id, like_status: posts[index].isBookmarked),
                    responseType: LikeResponseDTO.self
                )
            } catch {
                posts[index].isBookmarked = previousState
                errorMessage = "북마크 처리에 실패했습니다."
            }
        }
    }
    
    func loadMore() async {
        guard !isLoading else { return }
        if selectedTab != .members {
            await fetchPosts()
        }
    }
}

// - Cursor 기반 pagination Problem
// Category 문제
// Free, Greeting, Schedule
// 각 category에 대해서 fetching을 수행하면 paging은 문제가 없습니다.

// '전체'(moimID 기반) 으로 pagination을 하게될 경우 전체 post에 대한 정보들을 가져오게 됩니다.
// '전체'와 각'카테고리' pagination을 interliving 하게 수행할때 이미 fetch된 post에 대해서 fetch 가 될 수 있습니다.

// 중복 문제를 해결하기 위해
// postIdSet: Set<String>  set 자료형을 이용하여 각 Post를 unique하게 View 에서는 Model의 중복을 막을 수 있지만
// network상에서 중복 fetch 하게 됩니다.
