//
//  SingleChatModel.swift
//  FlatBread
//
//  Created by hwan on 11/12/25.
//

import Foundation

struct ChatRoomModel: Identifiable, Hashable {
    let id: String
    let createdAt: String
    let updatedAt: String
    let participants: [ChatUserModel]
    let lastChat: ChatMessageModel?
}

enum MessageSendStatus {
    case sending
    case sent
    case failed
}

enum MessageType: Hashable {
    case filesWithString(files: [String], message: String)
    case files(files: [String])
    case text(message: String)
    
    mutating func updateFiles(files: [String]) {
        switch self {
        case .files:
            self = .files(files: files)
        case .filesWithString(_, let message):
            self = .filesWithString(files: files, message: message)
        case .text(let message):
            self = .text(message: message)
        }
    }
    
    func getLastMessage() -> String {
        switch self {
        case .filesWithString(_, let message), .text(let message):
            return message
        case .files:
            return "사진"
        }
    }
}

struct ChatMessageModel: Identifiable, Hashable {
    let id: String
    let roomID: String
    var messegeType: MessageType
    let createdAt: String
    let sender: ChatUserModel
    var sendStatus: MessageSendStatus? // nil = 서버에서 받은 메시지, non-nil = 로컬에서 보낸 메시지
}

struct ChatUserModel: Identifiable, Hashable {
    let id: String
    let nick: String
    let profileImage: String?
}

extension ChatRoomModel {
    static var mockList: [ChatRoomModel] = [
        .init(
            id: UUID().uuidString,
            createdAt: "2025-11-14T06:04:52+0900",
            updatedAt: "2025-11-14T06:04:52+0900",
            participants: [
                .init(id: "65c9aa7032b0964405117d98a", nick: "서준일", profileImage: "/data/profiles/1707716900001.png")
            ],
            lastChat: .init(
                id: UUID().uuidString,
                roomID: UUID().uuidString,
                messegeType: .text(message: "하하하하하핳"),
                createdAt: "2025-11-14T06:04:52+0900",
                sender: .init(id: "65c9aa7032b0964405117d98a", nick: "서준일", profileImage: nil)
            )
        ),
        .init(
            id: UUID().uuidString,
            createdAt: "2025-11-14T06:01:52+0900",
            updatedAt: "2025-11-14T06:01:52+0900",
            participants: [
                .init(id: "65c9aa7032b0964405117d98b", nick: "안대현", profileImage: "/data/profiles/1707716900002.png")
            ],
            lastChat: .init(
                id: UUID().uuidString,
                roomID: UUID().uuidString,
                messegeType: .text(message: "안녕하세요"),
                createdAt: "2025-11-14T06:01:52+0900",
                sender: .init(id: "65c9aa7032b0964405117d98b", nick: "안대현", profileImage: nil)
            )
        ),
        .init(
            id: UUID().uuidString,
            createdAt: "2025-11-13T08:14:52+0900",
            updatedAt: "2025-11-13T08:14:52+0900",
            participants: [
                .init(id: "65c9aa7032b0964405117d98c", nick: "박형환", profileImage: "/data/profiles/1707716900003.png")
            ],
            lastChat: .init(
                id: UUID().uuidString,
                roomID: UUID().uuidString,
                messegeType: .text(message: "담배 한대 때리고 오겠습니다. 담배 한대 때리고 오겠습니다. 담배 한대 때리고 오겠습니다. 담배 한대 때리고 오겠습니다. 담배 한대 때리고 오겠습니다."),
                createdAt: "2025-11-13T08:14:52+0900",
                sender: .init(id: "65c9aa7032b0964405117d98c", nick: "박형환", profileImage: nil)
            )
        ),
        .init(
            id: UUID().uuidString,
            createdAt: "2025-11-12T06:04:52+0900",
            updatedAt: "2025-11-12T06:04:52+0900",
            participants: [
                .init(id: "65c9aa7032b0964405117d98d", nick: "김민성", profileImage: "/data/profiles/1707716900004.png")
            ],
            lastChat: .init(
                id: UUID().uuidString,
                roomID: UUID().uuidString,
                messegeType: .text(message: "하나의 픽셀은 3개의 서브픽셀로 이루어진걸 아시나요?"),
                createdAt: "2025-11-12T06:04:52+0900",
                sender: .init(id: "65c9aa7032b0964405117d98d", nick: "김민성", profileImage: nil)
            )
        )
    ]
}

extension ChatRoomModel {
    static var mock: ChatRoomModel {
        .init(
            id: UUID().uuidString,
            createdAt: "2025-05-06T06:04:52+0900",
            updatedAt: "2025-05-06T06:04:52+0900",
            participants: [
                .init(
                    id: UUID().uuidString,
                    nick: "Hwan",
                    profileImage: "/data/profiles/1707716853682.png"
                ),
                .init(
                    id: UUID().uuidString,
                    nick: "Hwan",
                    profileImage: "/data/profiles/1707716900000.png"
                )
            ],
            lastChat: .mock
        )
    }
}

extension ChatMessageModel {
    static var mock: ChatMessageModel {
        .init(
            id: UUID().uuidString,
            roomID: UUID().uuidString,
            messegeType: .text(message: "반갑습니다 :)"),
            createdAt: "2025-05-06T06:04:52+0900",
            sender: .init(
                id: "65c9aa6932b0964405117d97",
                nick: "Hwan",
                profileImage: "/data/profiles/1707716853682.png"
            ),
        )
    }

    /// 대량 더미 메시지 생성 (1000개)
    /// - Parameters:
    ///   - roomID: 채팅방 ID
    ///   - currentUserID: 현재 사용자 ID
    ///   - otherUser: 상대방 사용자
    /// - Returns: 1000개의 메시지 배열 (100일간 분산)
    static func dummyMessages(
        roomID: String,
        currentUserID: String,
        otherUser: ChatUserModel
    ) -> [ChatMessageModel] {
        let calendar = Calendar.current
        let now = Date()
        var messages: [ChatMessageModel] = []

        let messageTemplates = [
            "안녕하세요!",
            "오늘 날씨 좋네요",
            "점심 뭐 먹을까요?",
            "회의 몇 시에 하나요?",
            "넵 알겠습니다",
            "감사합니다",
            "수고하세요",
            "내일 봐요",
            "좋은 하루 되세요",
            "확인했습니다",
            "지금 출발합니다",
            "조금 늦을 것 같아요",
            "괜찮습니다",
            "알려주셔서 감사해요",
            "잘 부탁드립니다"
        ]

        // 메시지 생성 (하루 평균 10개)
        for dayOffset in 0..<10 {
            let messagesPerDay = Int.random(in: 8...12)

            for msgIndex in 0..<messagesPerDay {
                let hour = Int.random(in: 9...21)
                let minute = Int.random(in: 0...59)
                let isMyMessage = Bool.random()

                guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }

                var dateComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
                dateComponents.hour = hour
                dateComponents.minute = minute
                dateComponents.second = Int.random(in: 0...59)

                guard let messageDate = calendar.date(from: dateComponents) else { continue }

                let messageIndex = dayOffset * 10 + msgIndex
                let template = messageTemplates[Int.random(in: 0..<messageTemplates.count)]

                let messageType: MessageType
                if Int.random(in: 1...10) == 1 {
                    let imageCount = Int.random(in: 1...3)
                    let imageURLs = (0..<imageCount).map { _ in
                        "https://picsum.photos/seed/\(UUID().uuidString)/400/400"
                    }
                    messageType = Bool.random()
                        ? .files(files: imageURLs)
                        : .filesWithString(files: imageURLs, message: template)
                } else {
                    messageType = .text(message: "\(template) (\(messageIndex + 1))")
                }

                let message = ChatMessageModel(
                    id: UUID().uuidString,
                    roomID: roomID,
                    messegeType: messageType,
                    createdAt: ISO8601DateFormatter().string(from: messageDate),
                    sender: isMyMessage
                        ? ChatUserModel(id: currentUserID, nick: "나", profileImage: nil)
                        : otherUser
                )

                messages.append(message)
            }
        }
        return messages.sorted { $0.createdAt < $1.createdAt }
    }

    static func dummyMessages(
        roomID: String,
        currentUserID: String,
        otherUser: ChatUserModel,
        startDaysAgo: Int,
        count: Int
    ) -> [ChatMessageModel] {
        let calendar = Calendar.current
        let now = Date()
        var messages: [ChatMessageModel] = []

        let messageTemplates = [
            "안녕하세요!",
            "오늘 날씨 좋네요",
            "점심 뭐 먹을까요?",
            "넵 알겠습니다",
            "감사합니다"
        ]

        for i in 0..<count {
            let dayOffset = startDaysAgo + (i / 5)
            let hour = 9 + (i % 12)
            let minute = (i * 7) % 60

            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }

            var dateComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
            dateComponents.hour = hour
            dateComponents.minute = minute

            guard let messageDate = calendar.date(from: dateComponents) else { continue }

            let template = messageTemplates[i % messageTemplates.count]

            let message = ChatMessageModel(
                id: UUID().uuidString,
                roomID: roomID,
                messegeType: .text(message: "\(template) (\(i + 1))"),
                createdAt: ISO8601DateFormatter().string(from: messageDate),
                sender: (i % 2 == 0)
                    ? ChatUserModel(id: currentUserID, nick: "나", profileImage: nil)
                    : otherUser
            )

            messages.append(message)
        }

        return messages.sorted { $0.createdAt < $1.createdAt }
    }
}

extension ChatUserModel {
    static var mock: ChatUserModel {
        .init(
            id: UUID().uuidString,
            nick: "Hwan",
            profileImage: "/data/profiles/1707716853682.png"
        )
    }
}
