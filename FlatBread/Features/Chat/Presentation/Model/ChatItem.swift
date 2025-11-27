//
//  ChatMessageSection.swift
//  FlatBread
//
//  Created by hwan on 11/14/25.
//

import Foundation

/// 채팅 목록의 단일 아이템 (날짜 헤더 또는 메시지)
enum ChatItem: Identifiable, Hashable {
    case dateHeader(date: String, dateFormatted: String)
    case message(config: MessageDisplayConfig)

    var id: String {
        switch self {
        case .dateHeader(let date, _):
            return "header-\(date)"
        case .message(let config):
            return config.id
        }
    }
}

extension Date {
    /// 날짜를 채팅 섹션 헤더 형식으로 변환
    /// - Returns: "오늘", "어제", "2024년 11월 14일"
    func toChatSectionHeader() -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.startOfDay(for: self)

        let dayDifference = calendar.dateComponents([.day], from: targetDate, to: today).day ?? 0

        switch dayDifference {
        case 0:
            return "오늘"
        case 1:
            return "어제"
        default:
            let formatter = DateResolver.formatter
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "yyyy년 M월 d일"
            return formatter.string(from: self)
        }
    }
}

extension String {
    func toChatSectionHeader() -> String {
        if self.count == 10 && self.contains("-") {
            guard let date = self.toDate(format: "yyyy-MM-dd") else {
                return self
            }
            return date.toChatSectionHeader()
        } else {
            guard let date = self.toDate() else {
                return self
            }
            return date.toChatSectionHeader()
        }
    }
}
