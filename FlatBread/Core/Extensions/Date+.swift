//
//  Date+.swift
//  FlatBread
//
//  Created by hwan on 11/12/25.
//

import Foundation

enum DateResolver {
    static let formatter: DateFormatter = DateFormatter()
}

extension Date {
    func toString(format: String = "yyyy-MM-dd'T'HH:mm:ssZ") -> String {
        let formatter = DateResolver.formatter
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone.current  // 현지 타임존 사용
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    func relativeTimeString() -> String {
        let interval = Int(Date.now.timeIntervalSince(self))
        if interval < 60 {
            return "방금 전"
        } else if interval < 3600 {
            return "\(interval / 60)분 전"
        } else if interval < 86400 {
            return "\(interval / 3600)시간 전"
        } else {
            let formatter = DateResolver.formatter
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "yyyy.MM.dd"
            return formatter.string(from: self)
        }
    }
}

extension String {
    func toDate(format: String = "yyyy-MM-dd'T'HH:mm:ssZ") -> Date? {
        let formatter = DateResolver.formatter
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone.current  // 현지 타임존 사용
        formatter.dateFormat = format
        return formatter.date(from: self)
    }

    func relativeTime() -> String {
        guard let date = self.toDate() else { return "" }
        return date.relativeTimeString()
    }

    /// 날짜 문자열을 시간 형식으로 변환
    /// - Parameter timeFormat: 시간 포맷 (기본값: "a h:mm" - 오전/오후 표시)
    ///   - "a h:mm": 오전 2:30, 오후 11:45 (한국 채팅앱 표준)
    ///   - "HH:mm": 14:30, 23:45 (24시간 형식)
    /// - Returns: 포맷된 시간 문자열, 변환 실패 시 현재 시간
    func toTimeString(timeFormat: String = "a h:mm") -> String {
        guard let date = self.toDate() else {
            return Date.now.toString(format: timeFormat)
        }
        return date.toString(format: timeFormat)
    }

    /// 날짜 문자열을 날짜 키로 변환 (메시지 그룹핑용)
    /// - Returns: "2024-11-14" 형식의 날짜 키, 변환 실패 시 원본 문자열
    /// - Example: "2024-11-14T10:30:00Z" → "2024-11-14"
    func toDateKey() -> String {
        guard let date = self.toDate() else {
            return self
        }
        let formatter = DateResolver.formatter
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
