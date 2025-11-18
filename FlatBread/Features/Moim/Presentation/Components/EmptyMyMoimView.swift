//
//  EmptyMyMoimView.swift
//  FlatBread
//
//  Created by 서준일 on 11/6/25.
//

import SwiftUI

struct EmptyMyMoimView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("가입한 모임이 없습니다")
                .font(.title3)
                .foregroundStyle(.gray)

            Text("새로운 모임에 참여해보세요")
                .font(.body)
                .foregroundStyle(.gray.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    EmptyMyMoimView()
}
