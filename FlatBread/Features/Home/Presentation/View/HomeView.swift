//
//  HomeView.swift
//  FlatBread
//
//  Created by andev on 11/5/25.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject var viewModel: HomeViewModel
    
    let onTapCreateMoim: () -> Void // 모임 생성 버튼 탭시
    let onMoveToCategory: () -> Void // 카테고리 섹션 탭시
    let onMoveToMoimDetail: (String) -> Void // 모임 탭시 모임 디테일로 이동
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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
                            onTapBanner: { onMoveToMoimDetail($0.id) }
                        )
                        
                        CategorySectionCard( // 카테고리 섹션
                            items: viewModel.categoryItems,
                            onTapCategory: { viewModel.didTapCategory($0, onMoveToCategory) }
                        )
                        
                        MoimGroupSectionView(
                            items: viewModel.moimGroups,
                            onTapRow: { onMoveToMoimDetail($0.id) }
                        )
                    }
                    .padding(.vertical, 4)
                }
                .refreshable {
                    await viewModel.refreshHome()
                }
            }
            
            Button(action: {
                onTapCreateMoim()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color("juhwang"))
                    .clipShape(Circle())
                    .shadow(radius: 8)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
        .background(Color(.systemBackground))
    }
}

