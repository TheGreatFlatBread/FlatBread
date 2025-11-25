//
//  MyMoimViewUIModel.swift
//  FlatBread
//
//  Created by 서준일 on 11/6/25.
//

import Foundation

struct MyMoimViewUIModel: Hashable, Identifiable {
    var id: String { postID }
    let postID: String
    let category: String
    let title: String
    let content: String
    let location: String
    let memberCount: String
    let titleImageURL: String?
}

extension MyMoimViewUIModel {
    /// MyMoimViewUIModel을 TempPostMoimModel로 변환
    func toTempPostMoimModel() -> TempPostMoimModel {
        return TempPostMoimModel(
            id: postID,
            name: title,
            category: category,
            description: content,
            location: location.isEmpty ? nil : TempPostMoimModel.Location(
                name: location,
                coordinate: nil
            ),
            imageURLs: titleImageURL.map { [$0] } ?? [],
            memberCount: Int(memberCount) ?? 0,
            maxMembers: 100, // 기본값
            hashtags: [],
            createdAt: Date(),
            creator: TempPostMoimModel.Creator(
                id: "unknown",
                name: "Unknown",
                profileImageURL: nil
            ),
            memberIds: [],  // MyMoimView에서는 memberIds 정보가 없음
            membershipFee: 0
        )
    }

    static func getDummy() -> MyMoimViewUIModel {
        return MyMoimViewUIModel(
            postID: "test01010101",
            category: "운동/스포츠",
            title: "골프 함께해요 🔥",
            content: "라운딩 같이 가실분 !!!",
            location: "전국",
            memberCount: "12",
            titleImageURL: "https://images.unsplash.com/photo-1726091983472-a7da2540c492?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxoaWtpbmclMjBncm91cCUyMG91dGRvb3J8ZW58MXx8fHwxNzYyMzQwMTUyfDA&ixlib=rb-4.1.0&q=80&w=1080"
        )
    }
    
    static func getDummies() -> [MyMoimViewUIModel] {
        return [
            MyMoimViewUIModel(
                postID: "test01010101",
                category: "운동/스포츠",
                title: "골프 함께해요 🔥",
                content: "라운딩 같이 가실분 !!!",
                location: "전국",
                memberCount: "12",
                titleImageURL: "https://images.unsplash.com/photo-1726091983472-a7da2540c492?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxoaWtpbmclMjBncm91cCUyMG91dGRvb3J8ZW58MXx8fHwxNzYyMzQwMTUyfDA&ixlib=rb-4.1.0&q=80&w=1080"
            ),
            MyMoimViewUIModel(
                postID: "test01010102",
                category: "문화/공연/축제",
                title: "주말 영화 모임",
                content: "🎬 이번 주말 영화 보러 갈 분들 모집합니다!",
                location: "마포구",
                memberCount: "30",
                titleImageURL: "https://images.unsplash.com/photo-1643316791771-ac9b7b5a2238?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxib29rJTIwY2x1YiUyMHJlYWRpbmd8ZW58MXx8fHwxNzYyMzkwMDcwfDA&ixlib=rb-4.1.0&q=80&w=1080"
            ),
            MyMoimViewUIModel(
                postID: "test01010103",
                category: "사교/인맥",
                title: "맛집 탐방 모임",
                content: "🍜 맛집 탐방하실 분들 환영합니다! 매주 새로운 곳 방문",
                location: "서울",
                memberCount: "27",
                titleImageURL: "https://images.unsplash.com/photo-1759167581561-3b1fbe906b52?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxydW5uaW5nJTIwZml0bmVzcyUyMGdyb3VwfGVufDF8fHx8MTc2MjQxOTY4Nnww&ixlib=rb-4.1.0&q=80&w=1080"
            ),
            MyMoimViewUIModel(
                postID: "test01010104",
                category: "게임/오락",
                title: "보드게임 모임",
                content: "🎲 보드게임 좋아하시는 분들 모여요! 초보자 환영",
                location: "서울",
                memberCount: "42",
                titleImageURL: "https://images.unsplash.com/photo-1680022087238-eafecd5a8933?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb2ZmZWUlMjBtZWV0aW5nJTIwcGVvcGxlfGVufDF8fHx8MTc2MjM0MDE1MXww&ixlib=rb-4.1.0&q=80&w=1080"
            ),
            MyMoimViewUIModel(
                postID: "test01010105",
                category: "차/바이크",
                title: "테슬라 동호회",
                content: "🚘 서울 테슬라 오너 모임",
                location: "서울",
                memberCount: "125",
                titleImageURL: "https://images.unsplash.com/photo-1680022087238-eafecd5a8933?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb2ZmZWUlMjBtZWV0aW5nJTIwcGVvcGxlfGVufDF8fHx8MTc2MjM0MDE1MXww&ixlib=rb-4.1.0&q=80&w=1080"
            )
        ]
    }
}
