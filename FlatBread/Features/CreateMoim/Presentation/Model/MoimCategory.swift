//
//  MoimCategory.swift
//  FlatBread
//
//  Created by andev on 11/14/25.
//

import Foundation

struct MoimCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
}

// 더미 모델
extension Array where Element == MoimCategory {
    static var dummy10: [MoimCategory] {
        [
            "운동", "동네친구", "스터디", "게임", "음악",
            "독서", "사진", "러닝", "등산", "요리"
        ].map { MoimCategory(name: $0) }
    }
}
