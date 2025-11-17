//
//  MessageDisplayConfig.swift
//  FlatBread
//
//  Created by hwan on 11/14/25.
//

import Foundation

struct MessageDisplayConfig: Identifiable, Hashable {
    let id: String
    let message: ChatMessageModel
    let showProfile: Bool
    let showNickname: Bool
    let showTime: Bool
}

extension Array where Element == ChatMessageModel {
    func toDisplayConfigs(currentUserID: String) -> [MessageDisplayConfig] {
        guard !isEmpty else { return [] }
        return enumerated().map { index, message in
            let previousMessage = index > 0 ? self[index - 1] : nil
            let nextMessage = index < count - 1 ? self[index + 1] : nil

            let isMyMessage = message.sender.id == currentUserID
            let showProfile: Bool
            let showNickname: Bool
            let showTime: Bool

            if isMyMessage {
                showProfile = false
                showNickname = false
                showTime = shouldShowTime(
                    current: message,
                    next: nextMessage
                )
            } else {
                showProfile = shouldShowProfile(
                    current: message,
                    previous: previousMessage,
                    currentUserID: currentUserID
                )
                showNickname = showProfile
                
                showTime = shouldShowTime(
                    current: message,
                    next: nextMessage
                )
            }
            return MessageDisplayConfig(
                id: message.id,
                message: message,
                showProfile: showProfile,
                showNickname: showNickname,
                showTime: showTime
            )
        }
    }

    private func shouldShowProfile(
        current: ChatMessageModel,
        previous: ChatMessageModel?,
        currentUserID: String
    ) -> Bool {
        guard let previous else { return true }

        if previous.sender.id == currentUserID {
            return true
        }

        if previous.sender.id != current.sender.id {
            return true
        }

        if !isSameMinute(previous.createdAt, current.createdAt) {
            return true
        }

        return false
    }

    private func shouldShowTime(
        current: ChatMessageModel,
        next: ChatMessageModel?
    ) -> Bool {
        guard let next else { return true }

        if next.sender.id != current.sender.id {
            return true
        }

        if !isSameMinute(current.createdAt, next.createdAt) {
            return true
        }

        return false
    }

    private func isSameMinute(_ time1: String, _ time2: String) -> Bool {
        guard let date1 = time1.toDate(),
              let date2 = time2.toDate() else {
            return false
        }

        let calendar = Calendar.current
        let components1 = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date1)
        let components2 = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date2)

        return components1.year == components2.year &&
               components1.month == components2.month &&
               components1.day == components2.day &&
               components1.hour == components2.hour &&
               components1.minute == components2.minute
    }
}
