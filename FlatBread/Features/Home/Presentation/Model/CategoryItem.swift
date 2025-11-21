//
//  CategoryItem.swift
//  FlatBread
//
//  Created by andev on 11/10/25.
//

import SwiftUI

struct CategoryItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let symbol: String
    let tint: Color
}
