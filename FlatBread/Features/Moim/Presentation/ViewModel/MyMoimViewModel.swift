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
    @Published var recommendMoims: [MyMoimViewUIModel] = []
    @Published var myMoims: [MyMoimViewUIModel] = []
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

            let newMoims = response.data.compactMap { $0.toMyMoimViewUIModel() }
            myMoims.append(contentsOf: newMoims)
            nextCursor = response.next_cursor
            hasMoreData = response.next_cursor != "0"
        } catch {
            print("Failed to fetch moims: \(error)")
            hasMoreData = false
        }
    }
}

// MARK: - PostResponseDTO Extension
extension PostResponseDTO {
    func toMyMoimViewUIModel() -> MyMoimViewUIModel? {
        guard let postID = post_id else { return nil }
        guard let category = category else { return nil }
        guard let title = title else { return nil }
        
        return MyMoimViewUIModel(
            postID: postID,
            category: category,
            title: title,
            content: content ?? "",
            location: value6 ?? "전국",
            memberCount: value3 ?? "1명",
            titleImageURL: files.first
        )
    }
}

// MARK: - Preview ViewModel
final class PreviewMyMoimViewModel: ObservableObject {
    @Published var recommendMoims: [MyMoimViewUIModel] = []
    @Published var myMoims: [MyMoimViewUIModel] = []
    @Published var isLoading: Bool = false
    @Published var hasMoreData: Bool = false

    init() {
        let dummies = MyMoimViewUIModel.getDummies()
        self.myMoims = dummies
        self.recommendMoims = Array(dummies.prefix(3))
    }

    func loadMore() {
        // Preview용이므로 아무것도 하지 않음
    }
}
