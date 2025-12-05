//
//  MyMoimTopBar.swift
//  FlatBread
//
//  Created by 서준일 on 11/27/25.
//

import SwiftUI

struct MyMoimTopBar: View {
    let currentAddress: String
    let onSearchTap: () -> Void
    let onPlaneTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Text(currentAddress)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()

            Button(action: onSearchTap) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.primary)
                    .font(.system(size: 20))
            }
            .padding(.trailing, 16)

            Button(action: onPlaneTap) {
                Image(systemName: "paperplane")
                    .foregroundColor(.primary)
                    .font(.system(size: 20))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }
}
