//
//  ChatMessageRepository.swift
//  FlatBread
//
//  Created by hwan on 11/23/25.
//

import Foundation
import RealmSwift


final class ChatMessageRepository {

    private var realm: Realm {
        let config = Realm.Configuration(
            schemaVersion: 1,
            deleteRealmIfMigrationNeeded: true
        )
        return try! Realm(configuration: config)
    }
    
    static let shared = ChatMessageRepository()
    
    private init() {}

    func saveMessage(_ message: ChatMessageModel) {
        let entity = ChatMessageEntity.from(message)

        try! realm.write {
            realm.add(entity, update: .modified)
        }
    }

    func saveMessages(_ messages: [ChatMessageModel]) {
        let entities = messages.map { ChatMessageEntity.from($0) }

        try! realm.write {
            realm.add(entities, update: .modified)
        }
    }

    func getLatestMessages(roomID: String, participants: [ChatUserModel], limit: Int = 30) -> [ChatMessageModel] {
        let results = realm.objects(ChatMessageEntity.self)
            .filter("roomID == %@", roomID)
            .sorted(byKeyPath: "createdAt", ascending: false)
            .prefix(limit)

        let reversedEntities = Array(results.reversed())
        return reversedEntities.map { entity in
            entity.toDomain(participants: participants)
        }
    }

    /// Profiling 테스트용: 전체 메시지 로드 (limit 없음)
    func getAllMessagesInRoom(roomID: String, participants: [ChatUserModel]) -> [ChatMessageModel] {
        let results = realm.objects(ChatMessageEntity.self)
            .filter("roomID == %@", roomID)
            .sorted(byKeyPath: "createdAt", ascending: true) // 오래된 순서대로

        return results.map { entity in
            entity.toDomain(participants: participants)
        }
    }

    func getOlderMessages(roomID: String, participants: [ChatUserModel], before: Date, limit: Int = 30) -> [ChatMessageModel] {
        let results = realm.objects(ChatMessageEntity.self)
            .filter("roomID == %@ AND createdAt < %@", roomID, before)
            .sorted(byKeyPath: "createdAt", ascending: false)
            .prefix(limit)

        let reversedEntities = Array(results.reversed())
        return reversedEntities.map { entity in
            entity.toDomain(participants: participants)
        }
    }

    func getLastMessage(roomID: String, participants: [ChatUserModel]) -> ChatMessageModel? {
        let result = realm.objects(ChatMessageEntity.self)
            .filter("roomID == %@", roomID)
            .sorted(byKeyPath: "createdAt", ascending: false)
            .first

        return result?.toDomain(participants: participants)
    }

    func getMessage(id: String, participants: [ChatUserModel]) -> ChatMessageModel? {
        let entity = realm.object(ofType: ChatMessageEntity.self, forPrimaryKey: id)
        return entity?.toDomain(participants: participants)
    }

    func getMessageCount(roomID: String) -> Int {
        return realm.objects(ChatMessageEntity.self)
            .filter("roomID == %@", roomID)
            .count
    }

    func deleteMessage(id: String) {
        guard let entity = realm.object(ofType: ChatMessageEntity.self, forPrimaryKey: id) else {
            return
        }

        try! realm.write {
            realm.delete(entity)
        }
    }

    func deleteAllMessages(roomID: String) {
        let messages = realm.objects(ChatMessageEntity.self)
            .filter("roomID == %@", roomID)

        try! realm.write {
            realm.delete(messages)
        }
    }

    func deleteAll() {
        let allMessages = realm.objects(ChatMessageEntity.self)

        try! realm.write {
            realm.delete(allMessages)
        }
    }
}
