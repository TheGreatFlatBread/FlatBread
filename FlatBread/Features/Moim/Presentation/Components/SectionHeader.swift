//
//  SectionHeader.swift
//  FlatBread
//
//  Created by 서준일 on 11/6/25.
//

import SwiftUI

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title2.bold())
            .foregroundStyle(.primary)
            .textCase(nil)
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }
}

#Preview {
    SectionHeader(title: "요즘 뜨는 모임")
}
