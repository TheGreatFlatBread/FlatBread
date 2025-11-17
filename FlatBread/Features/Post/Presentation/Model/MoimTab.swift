//
//  TabEnum.swift
//  FlatBread
//
//  Created by hwan on 11/16/25.
//

import Foundation

enum MoimTab: String, CaseIterable {
    case schedule = "일정"
    case posts = "게시글"
    case members = "멤버"

    var title: String {
        return self.rawValue
    }

    var icon: String {
        switch self {
        case .schedule: return "calendar"
        case .posts: return "text.bubble"
        case .members: return "person.2"
        }
    }
}
