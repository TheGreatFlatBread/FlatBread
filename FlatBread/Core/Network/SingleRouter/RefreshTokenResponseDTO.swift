//
//  RefreshTokenResponseDTO.swift
//  FlatBread
//
//  Created by hwan on 11/7/25.
//

import Foundation

struct RefreshTokenResponseDTO {
    let accessToken: String?
    let refreshToken: String?
}

nonisolated extension RefreshTokenResponseDTO: Codable { }
