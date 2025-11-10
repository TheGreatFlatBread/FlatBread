//
//  CategoryItem.swift
//  FlatBread
//
//  Created by andev on 11/10/25.
//

import SwiftUI

// 샘플 모델
struct CategoryItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let symbol: String
    let tint: Color
}
