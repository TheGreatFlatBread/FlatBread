//
//  MoimGroupItem.swift
//  FlatBread
//
//  Created by andev on 11/12/25.
//

import Foundation

struct MoimGroupItem: Identifiable, Equatable {
    typealias ID = String
    let id: ID
    let title: String
    let subtitle: String
    let category: String
    let memberCount: Int
    let imageURL: String
}
