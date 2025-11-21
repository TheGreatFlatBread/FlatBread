//
//  MyMoimView.swift
//  FlatBread
//
//  Created by 서준일 on 11/6/25.
//

import SwiftUI

struct MyMoimView: View {
    @StateObject private var viewModel = MyMoimViewModel()
    @State private var selectedMoim: MyMoimViewUIModel?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    RecommendMoimsList(
                        moims: viewModel.recommendMoims,
                        onMoimTap: { moim in
                            selectedMoim = moim
                        }
                    )

                    MyJoinedMoimsList(
                        myMoims: viewModel.myMoims,
                        isLoading: viewModel.isLoading,
                        hasMoreData: viewModel.hasMoreData,
                        loadMore: viewModel.loadMore,
                        onMoimTap: { moim in
                            selectedMoim = moim
                        }
                    )
                }
            }
            .navigationDestination(item: $selectedMoim) { moim in
                PostListView(moim: moim.toTempPostMoimModel())
            }
        }
    }
}

// MARK: - Preview
private struct MyMoimViewPreview: View {
    @StateObject private var viewModel = PreviewMyMoimViewModel()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    RecommendMoimsList(moims: viewModel.recommendMoims)

                    MyJoinedMoimsList(
                        myMoims: viewModel.myMoims,
                        isLoading: viewModel.isLoading,
                        hasMoreData: viewModel.hasMoreData,
                        loadMore: viewModel.loadMore
                    )
                }
            }
        }
    }
}

#Preview {
    MyMoimViewPreview()
}
