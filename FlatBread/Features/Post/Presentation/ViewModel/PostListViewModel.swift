//
//  PostListViewModel.swift
//  FlatBread
//
//  Created by hwan on 11/16/25.
//

import Foundation
import Combine

final class PostListViewModel: ObservableObject {
    @Published var moim: TempPostMoimModel? = .mock

    @Published var posts: [PostUIModel] = PostUIModel.mocks
    @Published var schedules: [ScheduleUIModel] = ScheduleUIModel.mocks
    @Published var members: [MemberUIModel] = MemberUIModel.mocks

    @Published var selectedCategory: PostType = .all
    @Published var isLoading: Bool = false

    let moimId: String

    init(moimId: String) {
        self.moimId = moimId
    }

    init(moim: TempPostMoimModel) {
        self.moimId = moim.id
        self.moim = moim
    }

    func loadMoimData() {
        // TODO: 실제 API 구현
    }

    func loadPosts() {
        isLoading = true
        // TODO: 실제 API 구현
        isLoading = false
    }

    func loadSchedules() {
        // TODO: 실제 API 구현
    }

    func loadMembers() {
        loadMoimData()
    }

    var filteredPosts: [PostUIModel] {
        switch selectedCategory {
        case .all:
            return posts
        case .free:
            return posts.filter { $0.postType == .free }
        case .greeting:
            return posts.filter { $0.postType == .greeting }
        case .schedule:
            return posts.filter { $0.postType == .schedule }
        }
    }

    func toggleLike(for post: PostUIModel) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].isLiked.toggle()
        posts[index].likeCount += posts[index].isLiked ? 1 : -1
    }

    func toggleBookmark(for post: PostUIModel) {
        // TODO: 북마크 토글 API
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].isBookmarked.toggle()
    }

    func selectCategory(_ category: PostType) {
        selectedCategory = category
    }
}
