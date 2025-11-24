//
//  HomeViewModel.swift
//  FlatBread
//
//  Created by andev on 11/10/25.
//

import SwiftUI
import Combine

final class HomeViewModel: ObservableObject {
    
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    
    @Published var moimGroups: [MoimGroupItem] = []
    
    @Published var banners: [BannerItem] = []
    
    // Category detail navigation & data
    @Published var selectedCategoryTitle: String? = nil
    @Published var selectedCategoryGroups: [MoimGroupItem] = []

    @Published var categoryItems: [CategoryItem] = [
        .init(title: "운동/스포츠",    symbol: "sportscourt.fill",        tint: .blue),
        .init(title: "자기계발",      symbol: "brain.head.profile",      tint: .purple),
        .init(title: "인문학/책/글",  symbol: "book.closed.fill",        tint: .brown),
        .init(title: "문화/공연/축제", symbol: "theatermasks.fill",      tint: .pink),
        .init(title: "공예/만들기",    symbol: "scissors",               tint: .orange),
        .init(title: "봉사활동",      symbol: "hands.sparkles.fill",     tint: .green),
        .init(title: "차/바이크",     symbol: "car.fill",                tint: .gray),
        .init(title: "스포츠관람",    symbol: "sportscourt.circle.fill", tint: .indigo),
        .init(title: "요리/제조",     symbol: "fork.knife.circle.fill",  tint: .red),
        .init(title: "외국/언어",     symbol: "globe",                   tint: .teal),
        .init(title: "아웃도어/여행", symbol: "mountain.2.fill",         tint: .green),
        .init(title: "업종/직무",     symbol: "briefcase.fill",          tint: .brown),
        .init(title: "음악/악기",     symbol: "music.mic",               tint: .purple),
        .init(title: "댄스/무용",     symbol: "figure.dance",            tint: .pink),
        .init(title: "사교/인맥",     symbol: "person.3.fill",           tint: .orange),
        .init(title: "사진/영상",     symbol: "camera.fill",             tint: .blue),
        .init(title: "게임/오락",     symbol: "gamecontroller.fill",     tint: .green),
        .init(title: "반려동물",      symbol: "pawprint.fill",           tint: .brown)
    ]
    
    private var allCategories: [String] { categoryItems.map { $0.title } }

    init() {
        Task {
            await self.fetchBanners()
            await self.fetchMoimGroups()
        }
    }
    
    @MainActor
    func refreshHome() async {
        async let bannersTask: [BannerItem] = { @Sendable in
            do {
                return try await loadBanners()
            } catch {
                return []
            }
        }()
        async let groupsTask: [MoimGroupItem] = { @Sendable in
            do {
                return try await loadMoimGroups()
            } catch {
                return []
            }
        }()

        let (banners, groups) = await (bannersTask, groupsTask)
        self.banners = banners
        self.moimGroups = groups
    }

    private func loadBanners() async throws -> [BannerItem] {
        let response = try await networkService.request(
            PostRouter.getPostList(next: "", limit: "10", category: allCategories),
            responseType: PostListResponseDTO.self,
            interceptorType: .networkWithToken
        )
        return mapPostsToBanners(response)
    }

    private func loadMoimGroups() async throws -> [MoimGroupItem] {
        let response = try await networkService.request(
            PostRouter.getPostList(next: "", limit: "50", category: allCategories),
            responseType: PostListResponseDTO.self,
            interceptorType: .networkWithToken
        )
        return mapPostsToMoimGroups(response)
            .sorted { $0.memberCount > $1.memberCount }
    }

    func didTapCategory(_ item: CategoryItem, _ onMoveToCategory: @escaping () -> Void) {
        Task {
            self.selectedCategoryTitle = item.title
            do {
                let categories: [String] = [item.title]
                let response = try await self.networkService.request(
                    PostRouter.getPostList(next: "", limit: "50", category: categories),
                    responseType: PostListResponseDTO.self,
                    interceptorType: .networkWithToken
                )
                let groups = self.mapPostsToMoimGroups(response)
                    .sorted { $0.memberCount > $1.memberCount }
                await MainActor.run {
                    self.selectedCategoryGroups = groups
                    onMoveToCategory()
                }
            } catch {
                #if DEBUG
                print("[HomeViewModel] Failed to fetch category detail for (\(item.title)): \(error)")
                #endif
            }
        }
    }
    
    @MainActor
    private func updateBanners(_ items: [BannerItem]) {
        self.banners = items
    }

    private func mapPostsToBanners(_ dto: PostListResponseDTO) -> [BannerItem] {
        let posts = dto.data
        return posts.compactMap { post in
            let id = post.post_id ?? ""
            let imageURL = post.files.first ?? ""
            let title = post.title ?? ""
            let subtitle = post.content ?? ""
            // Skip if completely empty
            if id.isEmpty && title.isEmpty && subtitle.isEmpty && imageURL.isEmpty { return nil }
            return BannerItem(id: id, imageURL: imageURL, title: title, subtitle: subtitle)
        }
    }
    
    private func mapPostsToMoimGroups(_ dto: PostListResponseDTO) -> [MoimGroupItem] {
        dto.data.compactMap { post in
            let id = post.post_id ?? ""
            let title = post.title ?? ""
            let subtitle = post.content ?? ""
            let category = post.category ?? ""
            let memberCount = post.buyers.count
            let imageURL = post.files.first ?? ""
            if id.isEmpty && title.isEmpty && subtitle.isEmpty && imageURL.isEmpty { return nil }
            return MoimGroupItem(
                id: id,
                title: title,
                subtitle: subtitle,
                category: category,
                memberCount: memberCount,
                imageURL: imageURL
            )
        }
    }

    private func fetchBanners() async {
        do {
            let response = try await networkService.request(
                PostRouter.getPostList(next: "", limit: "10", category: allCategories),
                responseType: PostListResponseDTO.self,
                interceptorType: .networkWithToken
            )
            let banners = mapPostsToBanners(response)
            await MainActor.run {
                self.banners = banners
            }
        } catch {
            #if DEBUG
            print("[HomeViewModel] Failed to fetch banners: \(error)")
            #endif
        }
    }
    
    private func fetchMoimGroups() async {
        do {
            let response = try await networkService.request(
                PostRouter.getPostList(next: "", limit: "50", category: allCategories),
                responseType: PostListResponseDTO.self,
                interceptorType: .networkWithToken
            )
            let groups = mapPostsToMoimGroups(response)
                .sorted { $0.memberCount > $1.memberCount } // 멤버 많은 순 정렬
            await MainActor.run {
                self.moimGroups = groups
            }
        } catch {
            #if DEBUG
            print("[HomeViewModel] Failed to fetch moim groups: \(error)")
            #endif
        }
    }
    
    private func fetchMoimGroups(category: String?) async {
        do {
            let categories: [String] = {
                if let c = category, !c.isEmpty { return [c] }
                return []
            }()
            let response = try await networkService.request(
                PostRouter.getPostList(next: "", limit: "50", category: categories),
                responseType: PostListResponseDTO.self,
                interceptorType: .networkWithToken
            )
            let groups = mapPostsToMoimGroups(response)
                .sorted { $0.memberCount > $1.memberCount }
            await MainActor.run {
                self.moimGroups = groups
            }
        } catch {
            #if DEBUG
            print("[HomeViewModel] Failed to fetch moim groups for category (\(category ?? "")): \(error)")
            #endif
        }
    }
}

