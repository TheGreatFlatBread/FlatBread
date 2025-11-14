//
//  MyMoimViewUIModel.swift
//  FlatBread
//
//  Created by 서준일 on 11/6/25.
//

import Foundation

struct MyMoimViewUIModel: Hashable, Identifiable {
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
    let imageURLs: [String]
}

extension MyMoimViewUIModel {
    static func getDummy() -> MyMoimViewUIModel {
        return MyMoimViewUIModel(
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
            imageURLs: ["https://images.unsplash.com/photo-1680022087238-eafecd5a8933?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb2ZmZWUlMjBtZWV0aW5nJTIwcGVvcGxlfGVufDF8fHx8MTc2MjM0MDE1MXww&ixlib=rb-4.1.0&q=80&w=1080",]
        )
    }
    
    static func getDummies() -> [MyMoimViewUIModel] {
        return [
            MyMoimViewUIModel(
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
                commentCount: 12,
                imageURLs: ["https://images.unsplash.com/photo-1726091983472-a7da2540c492?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxoaWtpbmclMjBncm91cCUyMG91dGRvb3J8ZW58MXx8fHwxNzYyMzQwMTUyfDA&ixlib=rb-4.1.0&q=80&w=1080",]
            ),
            MyMoimViewUIModel(
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
                commentCount: 8,
                imageURLs: ["https://images.unsplash.com/photo-1643316791771-ac9b7b5a2238?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxib29rJTIwY2x1YiUyMHJlYWRpbmd8ZW58MXx8fHwxNzYyMzkwMDcwfDA&ixlib=rb-4.1.0&q=80&w=1080",]
            ),
            MyMoimViewUIModel(
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
                commentCount: 23,
                imageURLs: ["https://images.unsplash.com/photo-1759167581561-3b1fbe906b52?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxydW5uaW5nJTIwZml0bmVzcyUyMGdyb3VwfGVufDF8fHx8MTc2MjQxOTY4Nnww&ixlib=rb-4.1.0&q=80&w=1080",]
            ),
            MyMoimViewUIModel(
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
                commentCount: 5,
                imageURLs: ["https://images.unsplash.com/photo-1680022087238-eafecd5a8933?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb2ZmZWUlMjBtZWV0aW5nJTIwcGVvcGxlfGVufDF8fHx8MTc2MjM0MDE1MXww&ixlib=rb-4.1.0&q=80&w=1080",]
            ),
            MyMoimViewUIModel(
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
                commentCount: 17,
                imageURLs: ["https://images.unsplash.com/photo-1680022087238-eafecd5a8933?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb2ZmZWUlMjBtZWV0aW5nJTIwcGVvcGxlfGVufDF8fHx8MTc2MjM0MDE1MXww&ixlib=rb-4.1.0&q=80&w=1080",]
            )
        ]
    }
}
