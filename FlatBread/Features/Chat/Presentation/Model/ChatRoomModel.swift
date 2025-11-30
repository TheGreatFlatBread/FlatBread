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
    var lastChat: ChatMessageModel?
    var unreadCount: Int = 0
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
    var id: String
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

