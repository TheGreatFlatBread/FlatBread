//
//  MyMoimView.swift
//  FlatBread
//
//  Created by 서준일 on 11/6/25.
//

import SwiftUI

struct MyMoimView: View {
    @StateObject private var viewModel = MyMoimViewModel()

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
