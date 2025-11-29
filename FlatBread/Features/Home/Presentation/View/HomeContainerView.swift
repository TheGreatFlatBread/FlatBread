//
//  HomeContainerView.swift
//  FlatBread
//
//  Created by andev on 11/19/25.
//

import SwiftUI

struct HomeContainerView: View {

    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var router: TabRouter<HomeDestination>

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView {
                // 플로팅 버튼 탭 시 네비게이션 경로에 push
                router.navigate(to: .createMoim)
            } onMoveToCategory: {
                router.navigate(to: .categoryDetail)
            } onMoveToMoimDetail: { moimId in
                router.navigate(to: .moimDetail(moimId))
            }
            .environmentObject(viewModel)
            .navigationDestination(for: HomeDestination.self) { destination in
                switch destination {
                case .createMoim:
                    CreateMoimView()
                case .moimDetail(let moimId), .postList(let moimId):
                    PostListView(moimId: moimId)
                case .categoryDetail:
                    HomeCategoryDetailView(
                        title: viewModel.selectedCategoryTitle ?? "",
                        items: viewModel.selectedCategoryGroups,
                        onTapRow: { groupItem in
                            router.navigate(to: .moimDetail(groupItem.id))
                        }
                    )
                }
            }
        }
    }
}

#Preview {
    HomeContainerView()
}
