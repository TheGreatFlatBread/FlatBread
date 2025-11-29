//
//  ChatRoomRepository.swift
//  FlatBread
//
//  Created by hwan on 11/23/25.
//

import Foundation
import RealmSwift

final class ChatRoomRepository {

    private var realm: Realm {
        let config = Realm.Configuration(
            schemaVersion: 1,
            deleteRealmIfMigrationNeeded: true
        )
        return try! Realm(configuration: config)
    }

    static let shared = ChatRoomRepository()
    
    private init() {}

    func saveRoom(_ room: ChatRoomModel) {
        let entity = ChatRoomEntity.from(room)

        try! realm.write {
            realm.add(entity, update: .modified)
        }
    }

    func saveRooms(_ rooms: [ChatRoomModel]) {
        try! realm.write {
            for room in rooms {
                let local = realm.object(ofType: ChatRoomEntity.self, forPrimaryKey: room.id)
                let newEntity = ChatRoomEntity.from(room)
                if let local {
                    newEntity.lastReadMessageId = local.lastReadMessageId
                }
                realm.add(newEntity, update: .modified)
            }
        }
    }

    func updateRoomTime(roomID: String, updatedAt: Date) {
        guard let entity = realm.object(ofType: ChatRoomEntity.self, forPrimaryKey: roomID) else {
            return
        }

        try! realm.write {
            entity.updatedAt = updatedAt
        }
    }

    func getAllRooms() -> [ChatRoomModel] {
        let roomEntities = realm.objects(ChatRoomEntity.self)
            .sorted(byKeyPath: "updatedAt", ascending: false)

        return Array(roomEntities).map { entity in
            let participants = Array(entity.participants.map { participant in
                ChatUserModel(
                    id: participant.userID,
                    nick: participant.nick,
                    profileImage: participant.profileImage
                )
            })

            let lastMessage = ChatMessageRepository.shared.getLastMessage(roomID: entity.id, participants: participants)
            return entity.toDomain(lastMessage: lastMessage)
        }
    }

    func getRoom(id: String) -> ChatRoomModel? {
        guard let entity = realm.object(ofType: ChatRoomEntity.self, forPrimaryKey: id) else {
            return nil
        }

        let participants = Array(entity.participants.map { participant in
            ChatUserModel(
                id: participant.userID,
                nick: participant.nick,
                profileImage: participant.profileImage
            )
        })

        let lastMessage = ChatMessageRepository.shared.getLastMessage(roomID: id, participants: participants)
        return entity.toDomain(lastMessage: lastMessage)
    }

    func getRoomCount() -> Int {
        realm.objects(ChatRoomEntity.self).count
    }

    func roomExists(id: String) -> Bool {
        realm.object(ofType: ChatRoomEntity.self, forPrimaryKey: id) != nil
    }

    func deleteRoom(id: String) {
        guard let entity = realm.object(ofType: ChatRoomEntity.self, forPrimaryKey: id) else {
            return
        }

        try! realm.write {
            realm.delete(entity)
        }
        
        ChatMessageRepository.shared.deleteAllMessages(roomID: id)
    }

    func deleteAll() {
        let allRooms = realm.objects(ChatRoomEntity.self)

        try! realm.write {
            realm.delete(allRooms)
        }
        
        ChatMessageRepository.shared.deleteAll()
    }
}
