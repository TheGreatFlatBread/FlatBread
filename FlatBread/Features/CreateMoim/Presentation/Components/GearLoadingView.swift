//
//  GearLoadingView.swift
//  FlatBread
//
//  Created by andev on 11/19/25.
//

import SwiftUI

struct GearLoadingView: View {
    let progress: Double   // 0.0 ~ 1.0

    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 16, weight: .semibold))
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: 1)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
                .onAppear { isAnimating = true }

            Text("업로드 중... \(Int(progress * 100))%")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
}
