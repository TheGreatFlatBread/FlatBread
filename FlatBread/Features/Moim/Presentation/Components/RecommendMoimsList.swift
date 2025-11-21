//
//  RecommendMoimsList.swift
//  FlatBread
//
//  Created by 서준일 on 11/6/25.
//

import SwiftUI

struct RecommendMoimsList: View {
    let moims: [MyMoimViewUIModel]
    let onMoimTap: ((MyMoimViewUIModel) -> Void)?

    init(moims: [MyMoimViewUIModel], onMoimTap: ((MyMoimViewUIModel) -> Void)? = nil) {
        self.moims = moims
        self.onMoimTap = onMoimTap
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "요즘 뜨는 모임")

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(moims) { item in
                        MyMoimCell(moim: item) {
                            onMoimTap?(item)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    RecommendMoimsList(moims: MyMoimViewUIModel.getDummies())
}
