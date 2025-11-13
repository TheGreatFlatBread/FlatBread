//
//  HomeView.swift
//  FlatBread
//
//  Created by andev on 11/5/25.
//

import SwiftUI

struct HomeView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 최상단 커스텀 헤더
            HomeTopBarView(
                title: "FlatBread", // 앱 로고 텍스트
                onSearchTap: {
                    // TODO: 검색 화면으로 이동
                    print("Search tapped")
                }
            )
            
            ScrollView {
                VStack(spacing: 24) {
                    BannerCarouselView( // 배너 캐러셀
                        items: viewModel.banners,
                        onTapBanner: { viewModel.didTapBanner($0) }
                    )
                    
                    CategorySectionCard( // 카테고리 섹션
                        items: viewModel.categoryItems,
                        onTapCategory: { viewModel.didTapCategory($0) }
                    )
                    MoimGroupSectionView(
                        items: viewModel.moimGroups,
                        onTapRow: { viewModel.didTapMoimGroup($0)
                        }
                    )
                }
                .padding(.vertical, 4)
            }
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    HomeView()
}
