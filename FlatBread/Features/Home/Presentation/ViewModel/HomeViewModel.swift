//
//  HomeViewModel.swift
//  FlatBread
//
//  Created by andev on 11/10/25.
//

import SwiftUI
import Combine

final class HomeViewModel: ObservableObject {
    
    @Published var banners: [BannerItem] = [
        .init(
            imageURL: "https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=1200&q=80",
            title: "모임타이틀모임타이틀\n모이면 최저가에!",
            subtitle: "모임 전용 쿠폰 & 이벤트"
        ),
        .init(
            imageURL: "https://images.unsplash.com/photo-1515879218367-8466d910aaa4?auto=format&fit=crop&w=1200&q=80",
            title: "모임타이틀모임타이틀모임타이틀",
            subtitle: "지금 놓치면 1년 기다려야 해요"
        ),
        .init(
            imageURL: "https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=1200&q=80",
            title: "모임타이틀모임타이틀",
            subtitle: "담요 · 향초 · 머그컵 만드는 모임"
        )
    ]

    func didTapBanner(_ banner: BannerItem) {
        // TODO: 배너 상세 이동 / 웹뷰 열기 등
        print("Tapped banner: \(banner.title)")
    }

    // 카테고리 섹션에 보여줄 데이터
    @Published var categoryItems: [CategoryItem] = [
        .init(title: "추천 호스트", symbol: "heart.fill", tint: .red),
        .init(title: "소규모 모임", symbol: "person.2.fill", tint: .yellow),
        .init(title: "주말 모임", symbol: "calendar.badge.clock", tint: .red),
        .init(title: "당일 모임", symbol: "alarm.fill", tint: .red),
        .init(title: "대규모 모임", symbol: "person.3.sequence.fill", tint: .orange),
        .init(title: "넓적빵 PICK", symbol: "hand.thumbsup.fill", tint: .pink),
        .init(title: "클래스", symbol: "pencil.and.outline", tint: .teal),
        .init(title: "파티", symbol: "party.popper.fill", tint: .purple),
        .init(title: "칼퇴각 모임", symbol: "figure.run", tint: .yellow),
        .init(title: "선착순 할인", symbol: "ticket.fill", tint: .red)
    ]

    // 아이템 탭 액션 (추후 네비게이션/필터링 로직 연결)
    func didTapCategory(_ item: CategoryItem) {
        // TODO: 라우팅 / 필터링 / 트래킹 등
        print("Tapped category: \(item.title)")
    }
}
