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
            Text("이런 모임 어때요?")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
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
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemGray6))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.black.opacity(0.04), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
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
    .background(Color(.systemGray6))
}
