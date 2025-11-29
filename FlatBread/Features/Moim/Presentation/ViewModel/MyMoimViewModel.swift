//
//  MyMoimViewModel.swift
//  FlatBread
//
//  Created by 서준일 on 11/7/25.
//

import Foundation
import Combine

final class MyMoimViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var recommendMoims: [MoimSearchResultUIModel] = []
    @Published var myMoims: [MoimSearchResultUIModel] = []
    @Published var isLoadingMore: Bool = false
    @Published var hasMoreData: Bool = true

    var isLoading: Bool {
        isLoadingMore
    }

    var userData: MyMoimProfile? = nil

    // MARK: - Private Properties
    let networkService: AsyncNetworkService
    var nextCursor: String = ""
    let limit: String = "3"

    // MARK: - Initialization
    init() {
        self.networkService = NetworkServiceFactory.shared.makeNetworkService()
    }

    @MainActor
    func loadData() async {
        // 기존 데이터 초기화
        recommendMoims = []
        myMoims = []
        nextCursor = ""
        hasMoreData = true

        // 순차 실행: 데이터 로드 순서 보장
        await fetchRecommendMoims()

        // 내 모임 데이터 수집 (결제 + 프로필 + 좋아요)
        var allMyMoims: [MoimSearchResultUIModel] = []

        let paymentAndProfileMoims = await fetchMyMoimsData()
        allMyMoims.append(contentsOf: paymentAndProfileMoims)

        let likedMoims = await fetchLikedMoims()
        allMyMoims.append(contentsOf: likedMoims)

        // ID 기반 중복 제거
        var seenIds = Set<String>()
        let uniqueMoims = allMyMoims.filter { moim in
            if seenIds.contains(moim.id) {
                return false
            } else {
                seenIds.insert(moim.id)
                return true
            }
        }

        myMoims = uniqueMoims

        await fetchMyProfile()
    }
}

// MARK: - Public Methods
extension MyMoimViewModel {
    func loadMore() {
        guard !isLoadingMore && hasMoreData else { return }
        print(#function)
        Task {
            await loadMoreLikedMoims()
        }
    }
}


// MARK: - Pagination
extension MyMoimViewModel {
    private func loadMoreLikedMoims() async {
        await MainActor.run {
            self.isLoadingMore = true
        }
        defer {
            Task { @MainActor in
                self.isLoadingMore = false
            }
        }

        let likedMoims = await fetchLikedMoims()

        await MainActor.run {
            // 중복 제거: 기존 myMoims에 없는 것만 추가
            let existingIds = Set(self.myMoims.map { $0.id })
            let newMoims = likedMoims.filter { !existingIds.contains($0.id) }
            self.myMoims.append(contentsOf: newMoims)
        }
    }
}

// MARK: - Data Fetching - Recommend Moims
extension MyMoimViewModel {
    private func fetchRecommendMoims() async {
        do {
            let moims = try await loadRecommendMoims()
            await MainActor.run {
                self.recommendMoims = moims
            }
        } catch {
            #if DEBUG
            print("[MyMoimViewModel] Failed to fetch recommend moims: \(error)")
            #endif
        }
    }

    private func loadRecommendMoims() async throws -> [MoimSearchResultUIModel] {
        let response = try await networkService.request(
            PostRouter.getPostList(
                next: "",
                limit: "20",
                category: MoimCategory.allCases.map { $0.rawValue }
            ),
            responseType: PostListResponseDTO.self
        )
        let allMoims = response.data.compactMap { $0.asSearchResultUIModel }
        return Array(allMoims.shuffled().prefix(8))
    }
}

// MARK: - Data Fetching - My Moims (Payment + Profile)
extension MyMoimViewModel {
    private func fetchMyMoimsData() async -> [MoimSearchResultUIModel] {
        // 병렬로 결제 & 프로필 postID 가져오기
        async let paymentTask: [String] = { @Sendable in
            do {
                return try await self.loadPaymentPostIds()
            } catch {
                #if DEBUG
                print("[MyMoimViewModel] Failed to fetch payment post ids: \(error)")
                #endif
                return []
            }
        }()

        async let profileTask: [String] = { @Sendable in
            do {
                return try await self.loadProfilePostIds()
            } catch {
                #if DEBUG
                print("[MyMoimViewModel] Failed to fetch profile post ids: \(error)")
                #endif
                return []
            }
        }()

        let (paymentIds, profileIds) = await (paymentTask, profileTask)

        let combinedIds = Array(Set(paymentIds + profileIds))

        let moimCategories = MoimCategory.allCases.map { $0.rawValue }
        let filteredMoims = await fetchAndFilterMoimsByCategory(postIds: combinedIds, categories: moimCategories)

        return filteredMoims
    }

    private func loadPaymentPostIds() async throws -> [String] {
        let paymentResponse = try await networkService.request(
            PaymentRouter.myPaymentList(request: PaymentListResponseDTO(data: [])),
            responseType: PaymentListResponseDTO.self
        )
        return paymentResponse.data.map { $0.postId }
    }

    private func loadProfilePostIds() async throws -> [String] {
        let profileResponse = try await networkService.request(
            UserRouter.getMeProfile,
            responseType: UserProfileResponseDTO.self,
            interceptorType: .networkWithToken
        )
        return profileResponse.postIDList
    }

    private func fetchAndFilterMoimsByCategory(postIds: [String], categories: [String]) async -> [MoimSearchResultUIModel] {
        let maxConcurrent = 5
        var moimsList: [MoimSearchResultUIModel] = []

        // TaskGroup으로 병렬 처리하되 동시 실행 수 제한
        await withTaskGroup(of: MoimSearchResultUIModel?.self) { group in
            var index = 0
            let pendingIds = postIds

            // 처음 5개 task 추가
            while index < min(maxConcurrent, pendingIds.count) {
                let postId = pendingIds[index]
                group.addTask {
                    await self.fetchSinglePost(postId: postId, categories: categories)
                }
                index += 1
            }

            // 하나씩 완료되면 새로운 task 추가
            for await result in group {
                if let moimModel = result {
                    moimsList.append(moimModel)
                }

                // 남은 postId가 있으면 새 task 추가
                if index < pendingIds.count {
                    let postId = pendingIds[index]
                    group.addTask {
                        await self.fetchSinglePost(postId: postId, categories: categories)
                    }
                    index += 1
                }
            }
        }

        return moimsList
    }

    private func fetchSinglePost(postId: String, categories: [String]) async -> MoimSearchResultUIModel? {
        do {
            let postResponse = try await networkService.request(
                PostRouter.getPost(postID: postId),
                responseType: PostResponseDTO.self
            )

            if let category = postResponse.category,
               categories.contains(category),
               let moimModel = postResponse.asSearchResultUIModel {
                return moimModel
            }
            return nil
        } catch {
            print("Failed to fetch post \(postId): \(error)")
            return nil
        }
    }
}

// MARK: - Data Fetching - Liked Moims
extension MyMoimViewModel {
    private func fetchLikedMoims() async -> [MoimSearchResultUIModel] {
        do {
            let (moims, cursor, hasMore) = try await loadLikedMoims(cursor: nextCursor)
            await MainActor.run {
                self.nextCursor = cursor
                self.hasMoreData = hasMore
            }
            return moims
        } catch {
            #if DEBUG
            print("[MyMoimViewModel] Failed to fetch liked moims: \(error)")
            #endif
            await MainActor.run {
                self.hasMoreData = false
            }
            return []
        }
    }

    private func loadLikedMoims(cursor: String) async throws -> ([MoimSearchResultUIModel], String, Bool) {
        let response = try await networkService.request(
            PostRouter.getMeLikePostListV2(
                next: cursor,
                limit: limit,
                category: []
            ),
            responseType: PostListResponseDTO.self
        )

        let moims = response.data.compactMap { $0.asSearchResultUIModel }
        let nextCursor = response.next_cursor
        let hasMore = response.next_cursor != "0"
        return (moims, nextCursor, hasMore)
    }
}

// MARK: - Profile
extension MyMoimViewModel {
    private func fetchMyProfile() async {
        do {
            let profile = try await loadMyProfile()
            if let profile = profile {
                await MainActor.run {
                    self.userData = profile
                }
            } else {
            }
        } catch {
            #if DEBUG
            print("[MyMoimViewModel] Failed to fetch user profile: \(error)")
            #endif
        }
    }

    private func loadMyProfile() async throws -> MyMoimProfile? {
        let responseDTO = try await networkService.request(
            UserRouter.getMeProfile,
            responseType: UserProfileResponseDTO.self,
            interceptorType: .networkWithToken
        )
        return responseDTO.asMyMoimProfile
    }
}

// MARK: - Preview ViewModel
final class PreviewMyMoimViewModel: ObservableObject {
    @Published var recommendMoims: [MoimSearchResultUIModel] = []
    @Published var myMoims: [MoimSearchResultUIModel] = []
    @Published var isLoading: Bool = false
    @Published var hasMoreData: Bool = false

    init() {
        self.myMoims = []
        self.recommendMoims = []
    }

    func loadMore() {
        // Preview용이므로 아무것도 하지 않음
    }
}
