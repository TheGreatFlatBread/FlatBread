//
//  CategoryIconCard.swift
//  FlatBread
//
//  Created by andev on 11/5/25.
//

import SwiftUI

struct CategoryIconCard: View {
    let title: String
    let systemImage: String
    let tint: Color
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(FBTypography.iconLarge)
                    .foregroundStyle(tint)
                    .frame(height: 32)

                Text(title)
                    .font(FBTypography.captionSmall)
                    .foregroundStyle(FBColor.Text.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 84)
            .fbCardStyle(
                cornerRadius: FBRadius.xl,
                fill: .white,
                border: .black.opacity(0.05),
                borderWidth: 1,
                shadowColor: .black.opacity(0.05),
                shadowRadius: 8,
                shadowX: 0,
                shadowY: 2
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
}

#Preview {
    CategoryIconCard(
        title: "추천 호스트",
        systemImage: "heart.fill",
        tint: .red
    )
    .padding()
    .background(FBColor.Background.input)
}
