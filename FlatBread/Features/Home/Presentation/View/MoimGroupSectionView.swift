//
//  MoimGroupSectionView.swift
//  FlatBread
//
//  Created by andev on 11/12/25.
//

import SwiftUI

struct MoimGroupSectionView: View {
    
    let items: [MoimGroupItem]
    var onTapRow: ((MoimGroupItem) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            Text("활동이 활발한 모임")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
            
            // 리스트
            VStack(spacing: 12) {
                ForEach(items) { item in
                    MoimGroupRowView(item: item, onTap: onTapRow)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}

#Preview {
    ScrollView {
        MoimGroupSectionView(
            items: HomeViewModel().moimGroups
        )
    }
    .background(Color(.systemBackground))
}
