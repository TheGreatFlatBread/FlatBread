import SwiftUI
import Foundation
import Combine

final class HomeCategoryDetailViewModel: ObservableObject {
    @Published private(set) var items: [MoimGroupItem] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var hasMore: Bool = true
    
    let title: String
    private let categories: [String]
    private var nextCursor: String = "" // server uses "0" to indicate last page; empty string for first request
    private let limit: Int
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    
    init(title: String, categories: [String], limit: Int = 3) {
        self.title = title
        self.categories = categories
        self.limit = limit
    }
    
    /**
     Loads the initial page of posts.
     
     The server uses the next_cursor parameter for pagination:
     - An empty string ("") indicates the first page.
     - A value of "0" indicates the last page (no more data).
     */
    @MainActor
    func loadInitial() async {
        guard !isLoading else { return }
        isLoading = true
        #if DEBUG
        print("[HomeCategoryDetail] loadInitial start: categories=\(categories), limit=\(limit)")
        #endif
        defer { isLoading = false }
        items = []
        nextCursor = "" // first page
        hasMore = true
        
        do {
            let response = try await networkService.request(
                PostRouter.getPostList(next: nextCursor, limit: String(limit), category: categories),
                responseType: PostListResponseDTO.self,
                interceptorType: .networkWithToken
            )
            let groups = Self.mapPostsToMoimGroups(response)
            self.items = groups
            self.nextCursor = response.next_cursor
            #if DEBUG
            print("[HomeCategoryDetail] loadInitial success: items=\(items.count), nextCursor=\(nextCursor), hasMore=\(nextCursor != "0")")
            #endif
            // server returns "0" when last page
            self.hasMore = (self.nextCursor != "0")
        } catch {
            #if DEBUG
            print("[HomeCategoryDetail] loadInitial failed: \(error)")
            #endif
            self.hasMore = false
        }
    }
    
    @MainActor
    func loadMoreIfNeeded(currentItem: MoimGroupItem?) async {
        guard let currentItem = currentItem else { return }
        guard hasMore, !isLoading else { return }
        #if DEBUG
        print("[HomeCategoryDetail] loadMoreIfNeeded called for itemId=\(currentItem.id)")
        #endif
        if let lastItem = items.last,
           lastItem.id == currentItem.id {
            await loadMore()
        }
    }
    
    @MainActor
    private func loadMore() async {
        guard hasMore, !isLoading else { return }
        #if DEBUG
        print("[HomeCategoryDetail] loadMore start: nextCursor=\(nextCursor), limit=\(limit)")
        #endif
        // if nextCursor == "0" stop
        guard nextCursor != "0" else {
            #if DEBUG
            print("[HomeCategoryDetail] loadMore aborted: reached last page (nextCursor=0)")
            #endif
            hasMore = false
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await networkService.request(
                PostRouter.getPostList(next: nextCursor, limit: String(limit), category: categories),
                responseType: PostListResponseDTO.self,
                interceptorType: .networkWithToken
            )
            let more = Self.mapPostsToMoimGroups(response)
            self.items.append(contentsOf: more)
            self.nextCursor = response.next_cursor
            #if DEBUG
            print("[HomeCategoryDetail] loadMore success: appended=\(more.count), total=\(items.count), nextCursor=\(nextCursor), hasMore=\(nextCursor != "0")")
            #endif
            self.hasMore = (self.nextCursor != "0")
        } catch {
            #if DEBUG
            print("[HomeCategoryDetail] loadMore failed: \(error)")
            #endif
            // Keep hasMore as-is or set false based on policy
        }
    }
    
    static func mapPostsToMoimGroups(_ dto: PostListResponseDTO) -> [MoimGroupItem] {
        var groups: [MoimGroupItem] = []
        
        for post in dto.data {
            let id = post.post_id ?? ""
            let title = post.title ?? ""
            let subtitle = post.content ?? ""
            let category = post.category ?? ""
            let imageURL = post.files.first ?? ""
            
            // Skip if id/title/subtitle/imageURL are all empty
            if id.isEmpty && title.isEmpty && subtitle.isEmpty && imageURL.isEmpty {
                continue
            }
            
            let likes2Count = post.likes2.count
            let likesLegacyCount = post.likes.count
            let buyersCount = Set(post.buyers).count
            let price = post.price ?? 0
            
            let freeMemberCount = (likes2Count > 0 ? likes2Count : likesLegacyCount) + 1
            let memberCount = (price <= 0) ? freeMemberCount : (buyersCount + 1)
            
            let group = MoimGroupItem(
                id: id,
                title: title,
                subtitle: subtitle,
                category: category,
                memberCount: memberCount,
                imageURL: imageURL
            )
            groups.append(group)
        }
        return groups
    }
}
