//
//  ScheduleModel.swift
//  FlatBread
//
//  Created by hwan on 11/16/25.
//

import Foundation

struct ScheduleUIModel: Identifiable, Hashable {
    let id: String
    let title: String
    let date: Date
    let location: String?
    let participantCount: Int
    let maxParticipants: Int
    let description: String?
}

// MARK: - Mock Data
extension ScheduleUIModel {
    static var mock: ScheduleUIModel {
        ScheduleUIModel(
            id: UUID().uuidString,
            title: "이번 주 월요일, 오후 3:00",
            date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
            location: "문래동 카페",
            participantCount: 1,
            maxParticipants: 4,
            description: "식물원 탐방"
        )
    }

    static var mocks: [ScheduleUIModel] {
        [
            mock,
            ScheduleUIModel(
                id: UUID().uuidString,
                title: "주말 모임",
                date: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
                location: "강남역",
                participantCount: 3,
                maxParticipants: 6,
                description: "주말 모임"
            ),
            ScheduleUIModel(
                id: UUID().uuidString,
                title: "정기 모임",
                date: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
                location: nil,
                participantCount: 5,
                maxParticipants: 10,
                description: "월례 정기 모임"
            )
        ]
    }
}
