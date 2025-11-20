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
    
    @Published var moimGroups: [MoimGroupItem] = [
        .init(
            title: "콤플레이 배드민턴 모임🔥 신입모집🔥",
            subtitle: "함께 성장하는 2030 배드민턴 모임! 🏸",
            category: "운동/스포츠",
            memberCount: 251,
            imageURL: "https://images.unsplash.com/photo-1518604666860-9ed391f76460?auto=format&fit=crop&w=600&q=80"
        ),
        .init(
            title: "1인 창업자 AI/디자인/네트워킹",
            subtitle: "창업, 디자인, 인공지능(AI) 활용 스터디",
            category: "자기계발",
            memberCount: 6,
            imageURL: "https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&w=600&q=80"
        ),
        .init(
            title: "데일리 한중 언어 교류 (韓中交流)",
            subtitle: "📌 한중 언어 교류 모임 안내",
            category: "외국어/언어",
            memberCount: 146,
            imageURL: "https://images.unsplash.com/photo-1496307042754-b4aa456c4a2d?auto=format&fit=crop&w=600&q=80"
        )
    ]
    
    @Published var banners: [BannerItem] = []
    
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

    init() {
        Task { [weak self] in
            await self?.fetchBanners()
        }
    }
    
    func didTapMoimGroup(_ moim: MoimGroupItem) {
        // TODO: 모임 상세 이동
        print("Tapped moimGroup: \(moim.title)")
    }
    
    func didTapBanner(_ banner: BannerItem) {
        // TODO: 배너 상세 이동 / 웹뷰 열기 등
        print("Tapped banner: \(banner.title)")
    }

    // 아이템 탭 액션 (추후 네비게이션/필터링 로직 연결)
    func didTapCategory(_ item: CategoryItem) {
        // TODO: 라우팅 / 필터링 / 트래킹 등
        print("Tapped category: \(item.title)")
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

    private func fetchBanners() async {
        do {
            let response = try await networkService.request(
                PostRouter.getPostList(next: "", limit: "50", category: []),
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
}

