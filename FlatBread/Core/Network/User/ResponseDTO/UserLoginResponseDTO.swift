//
//  UserLoginResponseDTO.swift
//  FlatBread
//
//  Created by hwan on 11/6/25.
//

import Foundation

struct UserLoginResponseDTO: Decodable {
    var userID: String?
    var email: String?
    var nick: String?
    var profileImage: String?
    var accessToken: String?
    var refreshToken: String?
    
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case email, nick, accessToken, refreshToken
    }
}
