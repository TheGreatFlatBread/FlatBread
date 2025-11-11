//
//  SearchUserResponseDTO.swift
//  FlatBread
//
//  Created by hwan on 11/6/25.
//

import Foundation

struct SearchUserResponseDTO {
    let data: [CreatorResponseDTO]
}

nonisolated extension SearchUserResponseDTO: Decodable { }
