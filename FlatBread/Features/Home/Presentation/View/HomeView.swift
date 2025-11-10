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
            CategorySectionCard(
                items: viewModel.categoryItems,
                onTapCategory: { item in
                    viewModel.didTapCategory(item)
                }
            )
        }
        .background(Color(.systemGray6))
    }
}

#Preview {
    HomeView()
}
