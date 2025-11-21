//
//  TempPostMoimModel.swift
//  FlatBread
//
//  Created by hwan on 11/16/25.
//

import Foundation
import CoreLocation

/// 임시 Moim 모델 (PostResponseDTO 기반)
/// TODO: 추후 통합 Moim 모델로 교체 예정
struct TempPostMoimModel: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let description: String?
    let location: Location?
    let imageURLs: [String]
    let memberCount: Int
    let maxMembers: Int
    let hashtags: [String]
    let createdAt: Date
    let creator: Creator
    let memberIds: [String]  // likes2 - 가입한 멤버 ID 리스트

    struct Location: Hashable {
        let name: String
        let coordinate: Coordinate?
    }

    struct Coordinate: Hashable {
        let latitude: Double
        let longitude: Double
    }

    struct Creator: Hashable {
        let id: String
        let name: String
        let profileImageURL: String?
    }
}

// MARK: - Mock Data
extension TempPostMoimModel {
    static var mock: TempPostMoimModel {
        TempPostMoimModel(
            id: "moim123",
            name: "자라나라 새싹",
            category: "스터디",
            description: "새싹에서 함께 성장하는 개발 스터디 모임입니다. #새싹 #스터디 #개발",
            location: Location(
                name: "문래동",
                coordinate: Coordinate(latitude: 37.517677, longitude: 126.886442)
            ),
            imageURLs: [
                "https://picsum.photos/400/300",
                "https://picsum.photos/400/301"
            ],
            memberCount: 4,
            maxMembers: 10,
            hashtags: ["새싹", "스터디", "개발"],
            createdAt: Date(),
            creator: Creator(
                id: "user123",
                name: "김철수",
                profileImageURL: nil
            ),
            memberIds: ["user456", "user789", "user012"]
        )
    }
}
