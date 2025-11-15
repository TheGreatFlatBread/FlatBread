//
//  MainMapCategoryButton.swift
//  FlatBread
//
//  Created by 김민성 on 11/11/25.
//

import SwiftUI

struct MainMapCategoryButton: View {
    
    @Binding var category: MainMapCategoryUIModel
    private let verticalInset: CGFloat = 10
    private let horizontalInset: CGFloat = 16
    private let clipShape = RoundedRectangle(cornerRadius: 30)
    
    var body: some View {
        Button {
            category.isSelected.toggle()
        } label: {
            
            HStack {
                Image(systemName: category.image)
                Text(category.name)
            }
            .padding(
                .init(top: verticalInset,
                      leading: horizontalInset,
                      bottom: verticalInset,
                      trailing: horizontalInset)
            )
            .background(.yellow.opacity(category.isSelected ? 1.0 : 0.6))
            .clipShape(clipShape)
            .overlay { clipShape.stroke(.orange, lineWidth: category.isSelected ? 3 : 0) }
        }
        .buttonStyle(.plain)
    }
    
}

#Preview {
    @Previewable @State var category = MainMapCategoryUIModel(name: "운동", image: "figure.run")
    MainMapCategoryButton(category: $category)
}
