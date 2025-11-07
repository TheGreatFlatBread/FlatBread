//
//  Moim.swift
//  FlatBread
//
//  Created by 서준일 on 11/6/25.
//

import Foundation

struct Moim: Hashable, Identifiable {
    var id: String { postID ?? UUID().uuidString }
    let postID: String?
    let category: String?
    let title: String?
    let content: String?
    let value1: String?
    let value2: String?
    let value3: String?
    let value4: String?
    let value5: String?
    let files: [String]
    let likes: [String]
    let likes2: [String]
    let hashTags: [String]
    let commentCount: Int?
}

extension Moim {
    static func getDummy() -> Moim {
        return Moim(
            postID: nil,
            category: "스포츠",
            title: "새싹 스터디 모임",
            content: "🌱새싹 스터디를 모집합니다! 관심있으신 분 DM 주세요 !!!",
            value1: nil,
            value2: nil,
            value3: nil,
            value4: "180",
            value5: "문래동",
            files: [],
            likes: [],
            likes2: [],
            hashTags: [],
            commentCount: nil,
        )
    }
    
    static func getDummies() -> [Moim] {
        return [
            Moim(
                postID: "1",
                category: "스포츠",
                title: "새싹 스터디 모임",
                content: "🌱새싹 스터디를 모집합니다! 관심있으신 분 DM 주세요 !!!",
                value1: nil,
                value2: nil,
                value3: nil,
                value4: "180",
                value5: "문래동",
                files: [],
                likes: [],
                likes2: [],
                hashTags: [],
                commentCount: 12
            ),
            Moim(
                postID: "2",
                category: "문화",
                title: "주말 영화 모임",
                content: "🎬 이번 주말 영화 보러 갈 분들 모집합니다!",
                value1: nil,
                value2: nil,
                value3: nil,
                value4: "25",
                value5: "홍대입구",
                files: [],
                likes: [],
                likes2: [],
                hashTags: [],
                commentCount: 8
            ),
            Moim(
                postID: "3",
                category: "음식",
                title: "맛집 탐방 모임",
                content: "🍜 맛집 탐방하실 분들 환영합니다! 매주 새로운 곳 방문",
                value1: nil,
                value2: nil,
                value3: nil,
                value4: "50",
                value5: "강남역",
                files: [],
                likes: [],
                likes2: [],
                hashTags: [],
                commentCount: 23
            ),
            Moim(
                postID: "4",
                category: "취미",
                title: "보드게임 모임",
                content: "🎲 보드게임 좋아하시는 분들 모여요! 초보자 환영",
                value1: nil,
                value2: nil,
                value3: nil,
                value4: "15",
                value5: "신촌",
                files: [],
                likes: [],
                likes2: [],
                hashTags: [],
                commentCount: 5
            ),
            Moim(
                postID: "5",
                category: "스포츠",
                title: "러닝 크루 모집",
                content: "🏃‍♂️ 주 3회 러닝 크루 멤버 모집중! 함께 달려요",
                value1: nil,
                value2: nil,
                value3: nil,
                value4: "32",
                value5: "한강공원",
                files: [],
                likes: [],
                likes2: [],
                hashTags: [],
                commentCount: 17
            )
        ]
    }
}
