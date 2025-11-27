//
//  ChatRoomEntity.swift
//  FlatBread
//
//  Created by hwan on 11/23/25.
//

import Foundation
import RealmSwift

final class ChatRoomEntity: Object {

    @Persisted(primaryKey: true) var id: String
    @Persisted var createdAt: Date
    @Persisted var updatedAt: Date
    @Persisted var participants: List<ChatParticipantEntity>

    convenience init(
        id: String,
        createdAt: Date,
        updatedAt: Date,
        participants: [ChatParticipantEntity]
    ) {
        self.init()
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.participants.append(objectsIn: participants)
    }
}

final class ChatParticipantEntity: EmbeddedObject {
    @Persisted var userID: String
    @Persisted var nick: String
    @Persisted var profileImage: String?

    convenience init(userID: String, nick: String, profileImage: String?) {
        self.init()
        self.userID = userID
        self.nick = nick
        self.profileImage = profileImage
    }
}

extension ChatRoomEntity {
    func toDomain(lastMessage: ChatMessageModel? = nil) -> ChatRoomModel {
        let participantModels: [ChatUserModel] = participants.map { participant in
            ChatUserModel(
                id: participant.userID,
                nick: participant.nick,
                profileImage: participant.profileImage
            )
        }

        return ChatRoomModel(
            id: id,
            createdAt: createdAt.toISO8601String(),
            updatedAt: updatedAt.toISO8601String(),
            participants: participantModels,
            lastChat: lastMessage
        )
    }

    static func from(_ model: ChatRoomModel) -> ChatRoomEntity {
        let participantEntities = model.participants.map { user in
            ChatParticipantEntity(
                userID: user.id,
                nick: user.nick,
                profileImage: user.profileImage
            )
        }

        return ChatRoomEntity(
            id: model.id,
            createdAt: model.createdAt.toDate() ?? Date(),
            updatedAt: model.updatedAt.toDate() ?? Date(),
            participants: participantEntities
        )
    }
}
