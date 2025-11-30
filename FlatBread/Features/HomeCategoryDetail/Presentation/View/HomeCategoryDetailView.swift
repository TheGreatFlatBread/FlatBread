import SwiftUI

struct HomeCategoryDetailView: View {
    @StateObject var viewModel: HomeCategoryDetailViewModel
    var onTapRow: ((MoimGroupItem) -> Void)? = nil

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.items) { item in
                    MoimGroupRowView(item: item, onTap: onTapRow)
                        .padding(.horizontal, 16)
                        .onAppear {
                            Task { await viewModel.loadMoreIfNeeded(currentItem: item) }
                        }
                }
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .padding(.vertical, 12)
        }
        .navigationTitle(viewModel.title)
        .task {
            await viewModel.loadInitial()
        }
    }
}

#Preview {
    let vm = HomeCategoryDetailViewModel(title: "운동/스포츠", categories: ["운동/스포츠"], limit: 20)
    NavigationStack {
        HomeCategoryDetailView(viewModel: vm)
    }
}
