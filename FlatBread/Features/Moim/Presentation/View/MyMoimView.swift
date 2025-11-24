//
//  MyMoimView.swift
//  FlatBread
//
//  Created by 서준일 on 11/6/25.
//

import SwiftUI

struct MyMoimView: View {
    @StateObject private var viewModel = MyMoimViewModel()
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
