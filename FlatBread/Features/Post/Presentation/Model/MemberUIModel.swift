//
//  MemberUIModel.swift
//  FlatBread
//
//  Created by hwan on 11/16/25.
//

import Foundation

struct MemberUIModel: Identifiable {
    let id: String
    let name: String
    let profileImageURL: String?
    let bio: String?
    let isLeader: Bool
    let joinedAt: Date
}

// MARK: - Mock Data
extension MemberUIModel {
    static var mock: MemberUIModel {
        MemberUIModel(
            id: UUID().uuidString,
            name: "김철수",
            profileImageURL: nil,
            bio: "안녕하세요, 잘 부탁드립니다!",
            isLeader: true,
            joinedAt: Date().addingTimeInterval(-30 * 24 * 60 * 60)
        )
    }

    static var mocks: [MemberUIModel] {
        [
            MemberUIModel(
                id: UUID().uuidString,
                name: "김철수",
                profileImageURL: nil,
                bio: "모임을 이끌고 있습니다",
                isLeader: true,
                joinedAt: Date().addingTimeInterval(-60 * 24 * 60 * 60)
            ),
            MemberUIModel(
                id: UUID().uuidString,
                name: "이영희",
                profileImageURL: nil,
                bio: "식물 키우는 걸 좋아합니다",
                isLeader: false,
                joinedAt: Date().addingTimeInterval(-45 * 24 * 60 * 60)
            ),
            MemberUIModel(
                id: UUID().uuidString,
                name: "박민수",
                profileImageURL: nil,
                bio: nil,
                isLeader: false,
                joinedAt: Date().addingTimeInterval(-20 * 24 * 60 * 60)
            ),
            MemberUIModel(
                id: UUID().uuidString,
                name: "최지원",
                profileImageURL: nil,
                bio: "새로 가입했어요!",
                isLeader: false,
                joinedAt: Date().addingTimeInterval(-5 * 24 * 60 * 60)
            )
        ]
    }
}
