//
//  LikeResponseDTO.swift
//  FlatBread
//
//  Created by hwan on 11/6/25.
//

import Foundation

struct LikeResponseDTO {
    let likeStatus: Bool?
    
    enum CodingKeys: String, CodingKey {
        case likeStatus = "like_status"
    }
}

nonisolated extension LikeResponseDTO: Decodable { }
