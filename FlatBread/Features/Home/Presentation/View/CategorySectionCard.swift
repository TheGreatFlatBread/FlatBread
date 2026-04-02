//
//  CategorySectionCard.swift
//  FlatBread
//
//  Created by andev on 11/5/25.
//

import SwiftUI

struct CategorySectionCard: View {

    let items: [CategoryItem]
    var onTapCategory: ((CategoryItem) -> Void)?

    /// 2행 고정 (세로 2줄)
    private let rows: [GridItem] =
        Array(repeating: GridItem(.fixed(84), spacing: 10), count: 2)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            FBSectionHeader(title: "이런 모임 어때요?", style: .large)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(
                    rows: rows,
                    alignment: .center,
                    spacing: 10
                ) {
                    ForEach(items, id: \.self.id) { item in
                        CategoryIconCard(
                            title: item.title,
                            systemImage: item.symbol,
                            tint: item.tint
                        ) {
                            onTapCategory?(item)
                        }
                        .frame(width: 90) // 한 칸 너비 고정
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .fbCardStyle(
            cornerRadius: 28,
            fill: FBColor.Background.input,
            border: .black.opacity(0.04),
            borderWidth: 1,
            shadowColor: .black.opacity(0.08),
            shadowRadius: 16,
            shadowX: 0,
            shadowY: 6
        )
        .padding(.horizontal, 12)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            CategorySectionCard(
                items: HomeViewModel().categoryItems,
                onTapCategory: { _ in }
            )
        }
    }
    .background(FBColor.Background.input)
}
