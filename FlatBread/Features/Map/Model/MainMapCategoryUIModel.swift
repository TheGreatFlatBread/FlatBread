//
//  MainMapCategoryUIModel.swift
//  FlatBread
//
//  Created by 김민성 on 11/11/25.
//

struct MainMapCategoryUIModel: Hashable {
    let name: String
    /// system image name
    let image: String?
    var isSelected: Bool
    
    init(name: String, image: String? = nil, isSelected: Bool = true) {
        self.name = name
        self.image = image
        self.isSelected = isSelected
    }
}
