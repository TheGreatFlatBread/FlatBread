//
//  RecommendMoimsList.swift
//  FlatBread
//
//  Created by 서준일 on 11/6/25.
//

import SwiftUI

struct RecommendMoimsList: View {
    let moims: [MoimSearchResultUIModel]
    let onMoimTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "새로 생긴 모임이에요", fontSize: .callout.bold())

            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(moims) { item in
                            MoimListCell(moim: .constant(item))
                                .frame(width: geometry.size.width * 0.9, height: 80)
                                .onTapGesture {
                                    onMoimTap(item.id)
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .frame(height: 80)
        }
    }
}

#Preview {
    RecommendMoimsList(
        moims: [],
        onMoimTap: { moimId in
            print("Moim tapped: \(moimId)")
        }
    )
}
