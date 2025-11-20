//
//  SectionHeader.swift
//  FlatBread
//
//  Created by 서준일 on 11/6/25.
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    let fontSize: Font
    
    init(title: String, fontSize: Font = .title2.bold()) {
        self.title = title
        self.fontSize = fontSize
    }
    
    var body: some View {
        Text(title)
            .font(fontSize)
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
