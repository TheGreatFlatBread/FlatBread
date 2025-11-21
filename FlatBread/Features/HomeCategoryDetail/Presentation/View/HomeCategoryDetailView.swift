import SwiftUI

struct HomeCategoryDetailView: View {
    var title: String = "카테고리"
    var items: [MoimGroupItem] = []
    var onTapRow: ((MoimGroupItem) -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(items) { item in
                    MoimGroupRowView(item: item, onTap: onTapRow)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
        }
        .navigationTitle(title)
    }
}

#Preview {
    NavigationStack {
        HomeCategoryDetailView(
            title: "운동/스포츠",
            items: HomeViewModel().moimGroups
        )
    }
}
