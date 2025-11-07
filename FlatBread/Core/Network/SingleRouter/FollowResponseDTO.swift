//
//  FollowResponseDTO.swift
//  FlatBread
//
//  Created by hwan on 11/6/25.
//

import Foundation


struct FollowResponseDTO {
    let followStatus: Bool?
    enum CodingKeys: String, CodingKey {
        case followStatus = "follow_status"
    }
}

nonisolated extension FollowResponseDTO: Decodable { }
