//
//  BannerCarouselView.swift
//  FlatBread
//
//  Created by andev on 11/10/25.
//

import SwiftUI

struct BannerCarouselView: View {

    let items: [BannerItem]
    var onTapBanner: ((BannerItem) -> Void)?

    @State private var selectedBannerID: BannerItem.ID?

    // 카드 간 간격
    private let itemSpacing: CGFloat = 0

    var body: some View {
        let currentIndex: Int = {
            if let selectedID = selectedBannerID,
               let index = items.firstIndex(where: { $0.id == selectedID }) {
                return index + 1
            } else {
                return items.isEmpty ? 0 : 1
            }
        }()

        ZStack(alignment: .topTrailing) {
            GeometryReader { proxy in
                let screenWidth = proxy.size.width

                let itemWidth = screenWidth * 0.85
                let sidePadding = (screenWidth - itemWidth) / 2

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: itemSpacing) {
                        ForEach(items) { item in
                            BannerCardView(item: item)
                                .frame(width: itemWidth)
                                .id(item.id)
                                // 스크롤 위치에 따라 크기, 투명도 변환
                                .scrollTransition(.interactive, axis: .horizontal) { view, phase in
                                    view
                                        .scaleEffect(phase.isIdentity ? 1.0 : 0.9)
                                        .opacity(phase.isIdentity ? 1.0 : 0.8)
                                }
                                .onTapGesture {
                                    onTapBanner?(item)
                                }
                        }
                    }
                    .scrollTargetLayout()
                    // 첫/마지막 카드도 중앙에 올 수 있게, 그리고 양옆이 보이게
                    .padding(.horizontal, sidePadding)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $selectedBannerID)
            }
            .frame(height: 280)

            Text("\(currentIndex) / \(items.count)")
                .font(.caption).bold()
                .foregroundStyle(FBColor.Text.inverse)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.black.opacity(0.25), in: Capsule())
                .padding(.trailing, 44)
                .padding(.top, 12)
        }
        .padding(.top, 8)
        .frame(height: 280)
    }
}

#Preview {
    BannerCarouselView(
        items: HomeViewModel().banners,
        onTapBanner: { _ in }
    )
    .background(FBColor.Background.input)
}
