//
//  CommentResponseDTO.swift
//  FlatBread
//
//  Created by hwan on 11/6/25.
//

import Foundation

struct CommentListResponseDTO: Decodable {
    let data: [CommentReplyResponseDTO]
}

struct CommentReplyResponseDTO: Decodable {
    let comment: CommentResponseDTO
    let replies: [CommentResponseDTO]
}

struct CommentResponseDTO: Decodable {
    var comment_id: String?
    var content: String?
    var reatedAt: String?
    var creator: CreatorResponseDTO?
}
