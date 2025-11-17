//
//  ChatResponseDTO+Mappper.swift
//  FlatBread
//
//  Created by hwan on 11/12/25.
//

import Foundation

extension ChatResponseDTO {
    func toVM() -> ChatRoomModel {
        ChatRoomModel(
            id: self.roomID ?? UUID().uuidString,
            createdAt: self.createdAt ?? Date.now.toString(),
            updatedAt: self.updatedAt ?? Date.now.toString(),
            participants: self.participants.map { $0.toVM() },
            lastChat: self.lastChat?.toVM()
        )
    }
}

extension CreatorResponseDTO {
    func toVM() -> ChatUserModel {
        ChatUserModel(
            id: self.user_id ?? UUID().uuidString,
            nick: self.nick ?? "",
            profileImage: self.profileImage ?? ""
        )
    }
}

extension ChatMessageResponseDTO {
    func toVM() -> ChatMessageModel {
        let messageType: MessageType
        if files.isEmpty {
            messageType = .text(message: self.content ?? "")
        } else if let content = self.content, !files.isEmpty, !content.isEmpty {
            messageType = .filesWithString(files: files, message: content)
        } else if !files.isEmpty {
            messageType = .files(files: files)
        } else {
            messageType = .text(message: self.content ?? "")
        }
        
        return ChatMessageModel(
            id: self.chatID ?? UUID().uuidString,
            roomID: self.roomID ?? UUID().uuidString,
            messegeType: messageType,
            createdAt: self.createdAt ?? Date.now.toString(),
            sender: self.sender?.toVM() ?? ChatUserModel(id: "", nick: "", profileImage: "")
        )
    }
}
