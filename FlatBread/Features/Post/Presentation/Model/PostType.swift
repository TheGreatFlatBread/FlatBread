//
//  PostType.swift
//  FlatBread
//
//  Created by hwan on 11/17/25.
//

import Foundation

enum PostType: String, CaseIterable {
    case all = "ALL"
    case free = "FREE"
    case greeting = "GREETING"
    case schedule = "SCHEDULE"

    var displayName: String {
        switch self {
        case .all: return "전체"
        case .free: return "자유 게시판"
        case .greeting: return "가입인사"
        case .schedule: return "모임일정"
        }
    }

    var categoryHashtag: String {
        switch self {
        case .all: return ""
        case .free: return "#FBP_FREE"
        case .greeting: return "#FBP_GREETING"
        case .schedule: return "#FBP_SCHEDULE"
        }
    }

    static func fromHashtags(_ hashtags: [String]) -> PostType? {
        if hashtags.contains("FBP_FREE") {
            return .free
        } else if hashtags.contains("FBP_GREETING") {
            return .greeting
        } else if hashtags.contains("FBP_SCHEDULE") {
            return .schedule
        }
        return nil
    }
}
