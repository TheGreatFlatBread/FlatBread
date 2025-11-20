//
//  BannerItem.swift
//  FlatBread
//
//  Created by andev on 11/10/25.
//

import Foundation

struct BannerItem: Identifiable, Equatable {
    typealias ID = String
    let id: ID
    let imageURL: String
    let title: String
    let subtitle: String
}
