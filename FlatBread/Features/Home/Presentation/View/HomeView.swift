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
        ScrollView {
            VStack(spacing: 24) {
                BannerCarouselView(
                    items: viewModel.banners,
                    onTapBanner: { banner in
                        viewModel.didTapBanner(banner)
                    }
                )

                CategorySectionCard(
                    items: viewModel.categoryItems,
                    onTapCategory: { item in
                        viewModel.didTapCategory(item)
                    }
                )
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    HomeView()
}
