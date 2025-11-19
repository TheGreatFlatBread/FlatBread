//
//  MainMapCategoryUIModel.swift
//  FlatBread
//
//  Created by 김민성 on 11/11/25.
//

struct MainMapCategoryUIModel: Hashable {
    let category: MoimCategory
    var isSelected: Bool
    
    init(category: MoimCategory, isSelected: Bool = true) {
        self.category = category
        self.isSelected = isSelected
    }
}
