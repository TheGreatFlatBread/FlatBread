//
//  ChatDTO.swift
//  FlatBread
//
//  Created by hwan on 11/12/25.
//

import Foundation

struct ChatResponseDTO: nonisolated Decodable {
    let roomID: String?
    let createdAt: String?
    let updatedAt: String?
    let participants: [CreatorResponseDTO]
    let lastChat: ChatMessageResponseDTO?

    enum CodingKeys: String, CodingKey {
        case roomID = "room_id"
        case createdAt
        case updatedAt
        case participants
        case lastChat
    }
}

struct ChatMessageResponseDTO: nonisolated Decodable {
    let chatID: String?
    let roomID: String?
    let content: String?
    let createdAt: String?
    let sender: CreatorResponseDTO?
    let files: [String]

    enum CodingKeys: String, CodingKey {
        case chatID = "chat_id"
        case roomID = "room_id"
        case content
        case createdAt
        case sender
        case files
    }
}

struct ChatListResponseDTO: nonisolated Decodable {
    let data: [ChatMessageResponseDTO]
}


