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
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(height: 32)

                Text(title)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 84)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.black.opacity(0.05), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
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
    .background(Color(.systemGray6))
}
