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
    @Published var isLoading: Bool = false
    @Published var hasMoreData: Bool = true
    
    var userData: MyMoimProfile? = nil

    // MARK: - Private Properties
    private let networkService: AsyncNetworkService
    private var nextCursor: String = ""
    private let limit: String = "5"
    
    init() {
        self.networkService = NetworkServiceFactory.shared.makeNetworkService()
        loadMoims()
    }

    // MARK: - Methods
    private func loadMoims() {
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.fetchRecommendMoims() }
                group.addTask { await self.fetchMyMoims() }
                group.addTask { await self.requestMyProfile() }
            }
        }
    }

    func loadMore() {
        guard !isLoading && hasMoreData else { return }
        print(#function)
        Task {
            await loadMoreLikedMoims()
        }
    }

    @MainActor
    private func loadMoreLikedMoims() async {
        isLoading = true
        defer { isLoading = false }

        let likedMoims = await fetchLikedMoims()
        myMoims.append(contentsOf: likedMoims)
    }

    @MainActor
    private func fetchRecommendMoims() async {
        do {
            let response = try await networkService.request(
                PostRouter.getPostList(
                    next: "",
                    limit: "3",
                    category: MoimCategory.allCases.map { $0.rawValue }
                ),
                responseType: PostListResponseDTO.self
            )

            let allMoims = response.data.compactMap { $0.asSearchResultUIModel }
            recommendMoims = Array(allMoims.shuffled().prefix(8))
        } catch {
            print("Failed to fetch recommend moims: \(error)")
        }
    }

    @MainActor
    private func fetchMyMoims() async {
        isLoading = true
        defer { isLoading = false }

        async let paymentPostIds = fetchPaymentPostIds()
        async let profilePostIds = fetchProfilePostIds()

        let (paymentIds, profileIds) = await (paymentPostIds, profilePostIds)

        let combinedIds = Array(Set(paymentIds + profileIds))

        let moimCategories = MoimCategory.allCases.map { $0.rawValue }
        let filteredMoims = await fetchAndFilterMoimsByCategory(postIds: combinedIds, categories: moimCategories)

        myMoims.append(contentsOf: filteredMoims)
    }

    private func fetchPaymentPostIds() async -> [String] {
        do {
            let paymentResponse = try await networkService.request(
                PaymentRouter.myPaymentList(request: PaymentListResponseDTO(data: [])),
                responseType: PaymentListResponseDTO.self
            )
            return paymentResponse.data.map { $0.postId }
        } catch {
            print("Failed to fetch payment list: \(error)")
            return []
        }
    }

    private func fetchProfilePostIds() async -> [String] {
        do {
            let profileResponse = try await networkService.request(
                UserRouter.getMeProfile,
                responseType: UserProfileResponseDTO.self,
                interceptorType: .networkWithToken
            )
            return profileResponse.postIDList
        } catch {
            print("Failed to fetch profile post ids: \(error)")
            return []
        }
    }

    private func fetchAndFilterMoimsByCategory(postIds: [String], categories: [String]) async -> [MoimSearchResultUIModel] {
        var moimsList: [MoimSearchResultUIModel] = []

        for postId in postIds {
            do {
                let postResponse = try await networkService.request(
                    PostRouter.getPost(postID: postId),
                    responseType: PostResponseDTO.self
                )

                if let category = postResponse.category,
                   categories.contains(category),
                   let moimModel = postResponse.asSearchResultUIModel {
                    moimsList.append(moimModel)
                }
            } catch {
                print("Failed to fetch post \(postId): \(error)")
                continue
            }
        }

        return moimsList
    }

    private func fetchLikedMoims() async -> [MoimSearchResultUIModel] {
        do {
            let response = try await networkService.request(
                PostRouter.getMeLikePostListV2(
                    next: nextCursor,
                    limit: limit,
                    category: []
                ),
                responseType: PostListResponseDTO.self
            )

            nextCursor = response.next_cursor
            hasMoreData = response.next_cursor != "0"
            return response.data.compactMap { $0.asSearchResultUIModel }
        } catch {
            print("Failed to fetch liked moims: \(error)")
            hasMoreData = false
            return []
        }
    }
    
    private func requestMyProfile() async {
        do {
            isLoading = true
            let responseDTO = try await networkService.request(
                UserRouter.getMeProfile,
                responseType: UserProfileResponseDTO.self,
                interceptorType: .networkWithToken
            )
            isLoading = false
            userData = responseDTO.asMyMoimProfile
        } catch {
            isLoading = false
        }
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
