import SwiftUI

struct HomeCategoryDetailView: View {
    var title: String = "카테고리"
    var items: [String] = [
        "샘플 아이템 1",
        "샘플 아이템 2",
        "샘플 아이템 3"
    ]

    var body: some View {
        List(items, id: \.self) { item in
            Text(item)
        }
        .navigationTitle(title)
    }
}

#Preview {
    NavigationStack {
        HomeCategoryDetailView(
            title: "운동/스포츠",
            items: ["농구", "축구", "수영"]
        )
    }
}
