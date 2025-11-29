//
//  ChipButton.swift
//  FlatBread
//
//  Created by andev on 11/14/25.
//

import SwiftUI

struct ChipButton: View {
    let title: String
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color("juhwang") : Color(.systemGray6))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(isSelected ? Color("juhwang") : Color(.systemGray4), lineWidth: 1)
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview() {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
            ChipButton(title: "운동", isSelected: false, action: {})
            ChipButton(title: "동네친구", isSelected: true, action: {})
            ChipButton(title: "스터디", isSelected: false, action: {})
            ChipButton(title: "게임", isSelected: false, action: {})
        }
        .padding(16)
    }
    .background(Color(.systemBackground))
}
