//
//  PostType.swift
//  FlatBread
//
//  Created by hwan on 11/17/25.
//

import Foundation

enum PostType: String, CaseIterable {
    case all = "ALL"           // 필터링 전용 (서버에는 없음)
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
        case .free: return "#자유게시판"
        case .greeting: return "#가입인사"
        case .schedule: return "#모임일정"
        }
    }

    static func fromHashtags(_ hashtags: [String]) -> PostType? {
        if hashtags.contains("자유게시판") {
            return .free
        } else if hashtags.contains("가입인사") {
            return .greeting
        } else if hashtags.contains("모임일정") {
            return .schedule
        }
        return nil
    }
}
