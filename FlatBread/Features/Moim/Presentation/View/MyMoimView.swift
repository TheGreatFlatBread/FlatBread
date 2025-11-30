//
//  MyMoimView.swift
//  FlatBread
//
//  Created by 서준일 on 11/6/25.
//

import SwiftUI

enum MyMoimNavigationRoot: Hashable {
    case postList(moimId: String)
    case chatList(currentUserID: String)
}

struct MyMoimView: View {
    @StateObject private var viewModel = MyMoimViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var navigationDestination: MyMoimNavigationRoot?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MyMoimTopBar(
                    currentAddress: locationManager.currentAddress,
                    onSearchTap: {
                        // 검색 액션
                    },
                    onPlaneTap: {
                        guard let userData = viewModel.userData else { return }
                        navigationDestination = .chatList(currentUserID: userData.userID)
                    }
                )

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        RecommendMoimsList(
                            moims: viewModel.recommendMoims,
                            onMoimTap: { moimId in
                                navigationDestination = .postList(moimId: moimId)
                            }
                        )

                        MyJoinedMoimsList(
                            myMoims: viewModel.myMoims,
                            isLoading: viewModel.isLoading,
                            hasMoreData: viewModel.hasMoreData,
                            loadMore: viewModel.loadMore,
                            onMoimTap: { moimId in
                                navigationDestination = .postList(moimId: moimId)
                            }
                        )
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadData()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationDestination(item: $navigationDestination) { destination in
                switch destination {
                case .postList(let moimId):
                    PostListView(moimId: moimId)
                case .chatList(let currentUserID):
                    MoimChatListView(currentUserID: currentUserID)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Preview
private struct MyMoimViewPreview: View {
    @StateObject private var viewModel = PreviewMyMoimViewModel()
    @State private var selectedMoimId: String?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    RecommendMoimsList(
                        moims: viewModel.recommendMoims,
                        onMoimTap: { moimId in
                            selectedMoimId = moimId
                        }
                    )

                    MyJoinedMoimsList(
                        myMoims: viewModel.myMoims,
                        isLoading: viewModel.isLoading,
                        hasMoreData: viewModel.hasMoreData,
                        loadMore: viewModel.loadMore,
                        onMoimTap: { moimId in
                            selectedMoimId = moimId
                        }
                    )
                }
            }
            .navigationDestination(item: $selectedMoimId) { moimId in
                PostListView(moimId: moimId)
            }
        }
    }
}

#Preview {
    MyMoimViewPreview()
}
