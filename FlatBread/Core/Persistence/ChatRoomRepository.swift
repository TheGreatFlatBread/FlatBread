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

    /// 채팅방의 마지막으로 읽은 메시지 ID 업데이트
    func markAsRead(roomID: String, lastMessageId: String) {
        guard let entity = realm.object(ofType: ChatRoomEntity.self, forPrimaryKey: roomID) else {
            return
        }

        try! realm.write {
            entity.lastReadMessageId = lastMessageId
        }
    }

    /// 읽지 않은 메시지 개수 계산
    /// - lastReadMessageId 이후의 메시지 중 마지막부터 역순으로 연속된 상대방 메시지만 카운트
    /// - 마지막 메시지가 내 메시지면 0
    func getUnreadCount(roomID: String, currentUserID: String) -> Int {
        guard let entity = realm.object(ofType: ChatRoomEntity.self, forPrimaryKey: roomID) else {
            return 0
        }

        // 1. 마지막 메시지 확인
        guard let lastMessage = realm.objects(ChatMessageEntity.self)
            .filter("roomID == %@", roomID)
            .sorted(byKeyPath: "createdAt", ascending: false)
            .first else {
            return 0
        }

        // 2. 마지막 메시지가 내 메시지면 0
        if lastMessage.senderID == currentUserID {
            return 0
        }

        // 3. lastReadMessageId 이후의 메시지만 가져오기
        let messagesToCheck: Results<ChatMessageEntity>

        if let lastReadId = entity.lastReadMessageId,
           let lastReadMessage = realm.object(ofType: ChatMessageEntity.self, forPrimaryKey: lastReadId) {
            // lastReadMessage의 createdAt 이후 메시지만
            messagesToCheck = realm.objects(ChatMessageEntity.self)
                .filter("roomID == %@ AND createdAt > %@", roomID, lastReadMessage.createdAt)
                .sorted(byKeyPath: "createdAt", ascending: true)
        } else {
            // lastReadMessageId가 없으면 모든 메시지
            messagesToCheck = realm.objects(ChatMessageEntity.self)
                .filter("roomID == %@", roomID)
                .sorted(byKeyPath: "createdAt", ascending: true)
        }

        // 4. 마지막부터 역순으로 연속된 상대방 메시지만 카운트
        var unreadCount = 0
        for message in messagesToCheck.reversed() {
            if message.senderID == currentUserID {
                break
            }
            unreadCount += 1
        }

        return unreadCount
    }

    func getAllRooms(currentUserID: String) -> [ChatRoomModel] {
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
            let unreadCount = getUnreadCount(roomID: entity.id, currentUserID: currentUserID)

            var room = entity.toDomain(lastMessage: lastMessage)
            room.unreadCount = unreadCount
            return room
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
