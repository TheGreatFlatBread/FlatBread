//
//  UserSignUpResponseDTO.swift
//  FlatBread
//
//  Created by hwan on 11/6/25.
//

import Foundation

struct UserSignUpResponseDTO: Decodable {
    let userID: String?
    let email: String?
    let nick: String?
    let accessToken: String?
    let refreshToken: String?
    
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case email, nick, accessToken, refreshToken
    }
}
