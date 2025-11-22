//
//  HomeContainerView.swift
//  FlatBread
//
//  Created by andev on 11/19/25.
//

import SwiftUI

enum HomeRoute: Hashable {
    case createMoim
    case moveToMoimDetail(moimId: String)
    case moveToCategory
}

struct HomeContainerView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            HomeView {
                // 플로팅 버튼 탭 시 네비게이션 경로에 push
                path.append(HomeRoute.createMoim)
            } onMoveToCategory: {
                path.append(HomeRoute.moveToCategory)
            } onMoveToMoimDetail: { moimId in
                path.append(HomeRoute.moveToMoimDetail(moimId: moimId))
            }
            .environmentObject(viewModel)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .createMoim:
                    CreateMoimView()
                case .moveToMoimDetail(let moimId):
                    PostListView(moimId: moimId)
                case .moveToCategory:
                    HomeCategoryDetailView(
                        title: viewModel.selectedCategoryTitle ?? "",
                        items: viewModel.selectedCategoryGroups,
                        onTapRow: { groupItem in
                            path.append(HomeRoute.moveToMoimDetail(moimId: groupItem.id))
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
