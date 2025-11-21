//
//  HomeContainerView.swift
//  FlatBread
//
//  Created by andev on 11/19/25.
//

import SwiftUI

enum HomeRoute: Hashable {
    case createMoim
}

struct HomeContainerView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            HomeView {
                // 플로팅 버튼 탭 시 네비게이션 경로에 push
                path.append(HomeRoute.createMoim)
            }
            .environmentObject(viewModel)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .createMoim:
                    CreateMoimView()
                }
            }
            .navigationDestination(isPresented: $viewModel.isShowingCategoryDetail) {
                HomeCategoryDetailView(
                    title: viewModel.selectedCategoryTitle ?? "",
                    items: viewModel.selectedCategoryGroups
                )
            }
        }
    }
}

#Preview {
    HomeContainerView()
}
