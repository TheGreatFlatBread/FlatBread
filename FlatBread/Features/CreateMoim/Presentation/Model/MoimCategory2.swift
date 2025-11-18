//
//  MoimCategory2.swift
//  FlatBread
//
//  Created by andev on 11/14/25.
//

import Foundation

struct MoimCategory2: Identifiable, Hashable {
    let id = UUID()
    let name: String
}

// 더미 모델
extension Array where Element == MoimCategory2 {
    static var dummy10: [MoimCategory2] {
        [
            "운동", "동네친구", "스터디", "게임", "음악",
            "독서", "사진", "러닝", "등산", "요리"
        ].map { MoimCategory2(name: $0) }
    }
}
