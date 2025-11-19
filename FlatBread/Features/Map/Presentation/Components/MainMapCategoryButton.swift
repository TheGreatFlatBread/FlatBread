//
//  MainMapCategoryButton.swift
//  FlatBread
//
//  Created by 김민성 on 11/11/25.
//

import SwiftUI

struct MainMapCategoryButton: View {
    
    @Binding var category: MainMapCategoryUIModel
    private let verticalInset: CGFloat = 6
    private let horizontalInset: CGFloat = 10
    private let clipShape = RoundedRectangle(cornerRadius: 15)
    
    var body: some View {
        Button {
            withAnimation {
                category.isSelected.toggle()
            }
        } label: {
            HStack {
                Text(category.category.rawValue)
            }
            .frame(height: 15)
            .padding(
                .init(top: verticalInset,
                      leading: horizontalInset,
                      bottom: verticalInset,
                      trailing: horizontalInset)
            )
            .background(.white.opacity(category.isSelected ? 1.0 : 0.7))
            .clipShape(clipShape)
            .overlay { clipShape.stroke(category.isSelected ? .orange : .white, lineWidth: 1.5) }
        }
        .buttonStyle(.plain)
        .font(.system(size: 13))
    }
    
}

#Preview {
    @Previewable @State var category = MainMapCategoryUIModel(category: .culturePerformancesFestivals)
    MainMapCategoryButton(category: $category)
}
