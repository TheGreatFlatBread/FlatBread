//
//  Date+.swift
//  FlatBread
//
//  Created by hwan on 11/12/25.
//

import Foundation

enum DateResolver {
    static let formatter: DateFormatter = DateFormatter()

    /// 밀리초 포함 ISO8601 formatter (API 응답용)
    static let isoFormatterWithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// 밀리초 없는 ISO8601 formatter (fallback용)
    static let isoFormatterWithoutFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

extension Date {
    func toString(format: String = "yyyy-MM-dd'T'HH:mm:ssZ") -> String {
        let formatter = DateResolver.formatter
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone.current  // 현지 타임존 사용
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    /// API용 ISO8601 UTC 포맷으로 변환 (밀리초 포함)
    /// - Returns: "2024-11-15T05:13:54.357Z" 형식의 UTC 시간 문자열
    func toISO8601String() -> String {
        DateResolver.isoFormatterWithFractionalSeconds.string(from: self)
    }
    
    func relativeTimeString() -> String {
        let calendar = Calendar.current
        let now = Date.now
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self, to: now)

        if let year = components.year, year > 0 {
            return "\(year)년 전"
        } else if let month = components.month, month > 0 {
            return "\(month)달 전"
        } else if let day = components.day, day > 0 {
            return "\(day)일 전"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)시간 전"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)분 전"
        } else {
            return "방금 전"
        }
    }
}

extension String {
    func toDate(format: String = "yyyy-MM-dd'T'HH:mm:ssZ") -> Date? {
        if self.contains("T") && self.hasSuffix("Z") {
            if let date = DateResolver.isoFormatterWithFractionalSeconds.date(from: self) {
                return date
            }
            if let date = DateResolver.isoFormatterWithoutFractionalSeconds.date(from: self) {
                return date
            }
        }

        // 일반 포맷 시도
        let formatter = DateResolver.formatter
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone.current
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
