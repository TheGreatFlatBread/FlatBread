//
//  SearchUserResponseDTO.swift
//  FlatBread
//
//  Created by hwan on 11/6/25.
//

import Foundation

struct SearchUserResponseDTO: Decodable {
    let data: [CreatorResponseDTO]
}
