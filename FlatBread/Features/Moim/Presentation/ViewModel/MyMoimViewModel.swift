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
            await fetchRecommendMoims()
            await fetchMyMoims()
        }
    }

    func loadMore() {
        guard !isLoading && hasMoreData else { return }
        print(#function)
        Task {
            await fetchMyMoims()
        }
    }

    @MainActor
    private func fetchRecommendMoims() async {
        do {
            let response = try await networkService.request(
                PostRouter.getPostList(
                    next: "",
                    limit: "20",
                    category: []
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

        do {
            let response = try await networkService.request(
                PostRouter.getMeLikePostListV2(
                    next: nextCursor,
                    limit: limit,
                    category: []
                ),
                responseType: PostListResponseDTO.self
            )

            let newMoims = response.data.compactMap { $0.asSearchResultUIModel }
            myMoims.append(contentsOf: newMoims)
            nextCursor = response.next_cursor
            hasMoreData = response.next_cursor != "0"
        } catch {
            print("Failed to fetch moims: \(error)")
            hasMoreData = false
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
