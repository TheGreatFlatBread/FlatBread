//
//  ChatMessageEntity.swift
//  FlatBread
//
//  Created by hwan on 11/23/25.
//

import Foundation
import RealmSwift


final class ChatMessageEntity: Object {
    
    @Persisted(primaryKey: true) var id: String
    @Persisted(indexed: true) var roomID: String
    @Persisted(indexed: true) var createdAt: Date
    @Persisted var content: String?
    @Persisted var files: List<String>
    @Persisted var senderID: String

    convenience init(
        id: String,
        roomID: String,
        createdAt: Date,
        content: String?,
        files: [String],
        senderID: String
    ) {
        self.init()
        self.id = id
        self.roomID = roomID
        self.createdAt = createdAt
        self.content = content
        self.files.append(objectsIn: files)
        self.senderID = senderID
    }
}

extension ChatMessageEntity {

    func toDomain(participants: [ChatUserModel]) -> ChatMessageModel {
        let fileArray = Array(files)
        let messageType: MessageType
        if let content = content, !content.isEmpty {
            if !fileArray.isEmpty {
                messageType = .filesWithString(files: fileArray, message: content)
            } else {
                messageType = .text(message: content)
            }
        } else if !fileArray.isEmpty {
            messageType = .files(files: fileArray)
        } else {
            messageType = .text(message: "")
        }

        let sender = participants.first(where: { $0.id == senderID })
                     ?? ChatUserModel(id: senderID, nick: "알 수 없음", profileImage: nil)

        return ChatMessageModel(
            id: id,
            roomID: roomID,
            messegeType: messageType,
            createdAt: createdAt.toISO8601String(),
            sender: sender,
            sendStatus: nil
        )
    }

    static func from(_ model: ChatMessageModel) -> ChatMessageEntity {
        let content: String?
        let files: [String]

        switch model.messegeType {
        case .text(let message):
            content = message
            files = []
        case .files(let fileList):
            content = nil
            files = fileList
        case .filesWithString(let fileList, let message):
            content = message
            files = fileList
        }

        let date = model.createdAt.toDate() ?? Date()

        return ChatMessageEntity(
            id: model.id,
            roomID: model.roomID,
            createdAt: date,
            content: content,
            files: files,
            senderID: model.sender.id
        )
    }
}
