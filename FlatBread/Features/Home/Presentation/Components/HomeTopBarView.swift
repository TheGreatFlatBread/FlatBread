//
//  HomeTopBarView.swift
//  FlatBread
//
//  Created by andev on 11/11/25.
//

import SwiftUI

struct HomeTopBarView: View {

    let title: String // 앱 로고 텍스트
    var onSearchTap: (() -> Void)?

    var body: some View {
        HStack {
            // 좌측 로고/텍스트
            Text(title)
                .font(FBTypography.brand)
                .foregroundStyle(FBColor.Text.primary)

            Spacer()

            // 우측 돋보기 버튼
            Button {
                onSearchTap?()
            } label: {
                Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(FBColor.Text.primary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())   // 탭 영역 확보
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(FBColor.Background.primary)
    }
}

#Preview {
    HomeTopBarView(title: "FlatBread", onSearchTap: {})
        .background(FBColor.Background.primary)
}
