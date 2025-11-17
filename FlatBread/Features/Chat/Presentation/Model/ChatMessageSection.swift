//
//  ChatMessageSection.swift
//  FlatBread
//
//  Created by hwan on 11/14/25.
//

import Foundation

struct ChatMessageSection: Identifiable, Hashable {
    let id: String
    let date: String
    let dateFormatted: String
    var messages: [ChatMessageModel]
    let displayConfigs: [MessageDisplayConfig]

    /// Section 생성 헬퍼
    /// - Parameters:
    ///   - date: 날짜 키 (yyyy-MM-dd)
    ///   - dateFormatted: 포맷된 날짜 헤더
    ///   - messages: 메시지 배열
    ///   - currentUserID: 현재 사용자 ID
    /// - Returns: displayConfigs가 계산된 Section
    static func create(
        date: String,
        dateFormatted: String,
        messages: [ChatMessageModel],
        currentUserID: String
    ) -> ChatMessageSection {
        ChatMessageSection(
            id: date,
            date: date,
            dateFormatted: dateFormatted,
            messages: messages,
            displayConfigs: messages.toDisplayConfigs(currentUserID: currentUserID)
        )
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
