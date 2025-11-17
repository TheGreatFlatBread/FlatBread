//
//  PostUIModel.swift
//  FlatBread
//
//  Created by hwan on 11/16/25.
//

import Foundation

struct PostUIModel: Identifiable {
    let id: String
    let moimId: String
    let author: Author
    let createdAt: Date
    let postType: PostType
    let content: String
    let hashtags: [String]
    let images: [String]
    let schedule: Schedule?
    var likeCount: Int
    var commentCount: Int
    var isBookmarked: Bool
    var isLiked: Bool

    struct Author: Identifiable, Equatable {
        let id: String
        let name: String
        let profileImageURL: String?
    }

    struct Schedule: Equatable {
        let date: Date
        let title: String
        let participantCount: Int
        let maxParticipants: Int
    }
}

extension PostUIModel {
    static var mock: PostUIModel {
        PostUIModel(
            id: UUID().uuidString,
            moimId: "moim123",
            author: Author(id: UUID().uuidString, name: "Laiika", profileImageURL: nil),
            createdAt: Date().addingTimeInterval(-2 * 24 * 60 * 60),
            postType: .schedule,
            content: "좋료 우리 동네 식물원 탐험하며 힐링🌿 #식물원 #힐링 #새싹\n우리 동네 식물원 탐험하며 힐링하는 모임에 여러분을 초대합니다. 바쁜 일상 속에서 잠시 멈추니 식물들이 주는 평화로움을 함께 느껴보는 시간을 가져요.\n\n이런 분들에게 추천합니다:\n...더보기",
            hashtags: ["식물원", "힐링", "새싹"],
            images: [],
            schedule: Schedule(
                date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
                title: "이번 주 월요일, 오후 3:00",
                participantCount: 1,
                maxParticipants: 4
            ),
            likeCount: 1,
            commentCount: 1,
            isBookmarked: false,
            isLiked: false
        )
    }

    static var mocks: [PostUIModel] {
        [
            PostUIModel(
                id: UUID().uuidString,
                moimId: "moim123",
                author: Author(id: UUID().uuidString, name: "Laiika", profileImageURL: nil),
                createdAt: Date().addingTimeInterval(-2 * 24 * 60 * 60),
                postType: .schedule,
                content: "좋료 우리 동네 식물원 탐험하며 힐링🌿 #식물원 #새싹\n우리 동네 식물원 탐험하며 힐링하는 모임에 여러분을 초대합니다. 바쁜 일상 속에서 잠시 멈추니 식물들이 주는 평화로움을 함께 느껴보는 시간을 가져요.",
                hashtags: ["식물원", "새싹"],
                images: ["https://picsum.photos/400/300"],
                schedule: Schedule(
                    date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
                    title: "이번 주 월요일, 오후 3:00",
                    participantCount: 1,
                    maxParticipants: 4
                ),
                likeCount: 8,
                commentCount: 3,
                isBookmarked: false,
                isLiked: false
            ),
            PostUIModel(
                id: UUID().uuidString,
                moimId: "moim123",
                author: Author(id: UUID().uuidString, name: "김철수", profileImageURL: nil),
                createdAt: Date().addingTimeInterval(-1 * 24 * 60 * 60),
                postType: .free,
                content: "안녕하세요! 오늘 날씨가 정말 좋네요. 다들 좋은 하루 보내세요~ #날씨좋음 #주말 주말에 뭐 하실 계획이신가요?",
                hashtags: ["날씨좋음", "주말"],
                images: ["https://picsum.photos/400/301"],
                schedule: nil,
                likeCount: 15,
                commentCount: 7,
                isBookmarked: false,
                isLiked: true
            ),
            PostUIModel(
                id: UUID().uuidString,
                moimId: "moim123",
                author: Author(id: UUID().uuidString, name: "이영희", profileImageURL: nil),
                createdAt: Date().addingTimeInterval(-5 * 60 * 60),
                postType: .greeting,
                content: "안녕하세요! 새로 가입했습니다. #새싹 #가입인사 식물 키우는 걸 정말 좋아하는데, 이 모임에서 많이 배우고 싶어요. 잘 부탁드립니다 :)",
                hashtags: ["새싹", "가입인사"],
                images: [],
                schedule: nil,
                likeCount: 22,
                commentCount: 12,
                isBookmarked: false,
                isLiked: false
            ),
            PostUIModel(
                id: UUID().uuidString,
                moimId: "moim123",
                author: Author(id: UUID().uuidString, name: "박민수", profileImageURL: nil),
                createdAt: Date().addingTimeInterval(-8 * 60 * 60),
                postType: .free,
                content: "오늘 집에서 키우던 다육이가 드디어 꽃을 피웠어요! 너무 예뻐서 공유합니다 ㅎㅎ #다육이 #식물키우기",
                hashtags: ["다육이", "식물키우기"],
                images: ["https://picsum.photos/400/302"],
                schedule: nil,
                likeCount: 31,
                commentCount: 18,
                isBookmarked: true,
                isLiked: true
            )
        ]
    }
}
