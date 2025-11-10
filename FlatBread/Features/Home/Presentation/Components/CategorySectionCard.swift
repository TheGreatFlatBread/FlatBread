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

    /// 5열 고정. 기기 너비에 따라 바꾸려면 count 조절
    private let columns: [GridItem] =
        Array(repeating: GridItem(.flexible(), spacing: 6), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("넓적빵 모임")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: columns, alignment: .center, spacing: 10) {
                ForEach(items) { item in
                    CategoryIconCard(
                        title: item.title,
                        systemImage: item.symbol,
                        tint: item.tint
                    ) {
                        onTapCategory?(item)
                    }
                }
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
