//
//  CommentUIModel.swift
//  FlatBread
//
//  Created by hwan on 11/16/25.
//

import Foundation

struct CommentUIModel: Identifiable {
    let id: String
    let authorId: String
    let authorName: String
    let profileImageURL: String?
    var content: String
    let createdAt: Date
    var replies: [CommentUIModel] = []

    var replyCount: Int {
        replies.count
    }
}

extension CommentUIModel {
    static func getDummies() -> [CommentUIModel] {
        [
            CommentUIModel(
                id: UUID().uuidString,
                authorId: "user1",
                authorName: "김철수",
                profileImageURL: nil,
                content: "저도 참여하고 싶어요!",
                createdAt: Date().addingTimeInterval(-7200)  // 2시간 전
            ),
            CommentUIModel(
                id: UUID().uuidString,
                authorId: "user2",
                authorName: "이영희",
                profileImageURL: nil,
                content: "시간 괜찮을까요?",
                createdAt: Date().addingTimeInterval(-3600)  // 1시간 전
            ),
            CommentUIModel(
                id: UUID().uuidString,
                authorId: "user3",
                authorName: "박민수",
                profileImageURL: nil,
                content: "기대됩니다!",
                createdAt: Date().addingTimeInterval(-1800)  // 30분 전
            )
        ]
    }
}
