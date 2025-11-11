//
//  CommentResponseDTO.swift
//  FlatBread
//
//  Created by hwan on 11/6/25.
//

import Foundation

struct CommentListResponseDTO {
    let data: [CommentReplyResponseDTO]
}

struct CommentReplyResponseDTO {
    let comment: CommentResponseDTO
    let replies: [CommentResponseDTO]
}

struct CommentResponseDTO {
    let commentID: String?
    let content: String?
    let createdAt: String?
    let creator: CreatorResponseDTO?
    
    enum CodingKeys: String, CodingKey {
        case commentID = "comment_id"
        case content, createdAt, creator
    }
}


struct CommentWriteResponseDTO {
    let content: String?
}


nonisolated extension CommentListResponseDTO: Decodable { }
nonisolated extension CommentReplyResponseDTO: Decodable { }
nonisolated extension CommentResponseDTO: Decodable { }
nonisolated extension CommentWriteResponseDTO: Decodable { }
