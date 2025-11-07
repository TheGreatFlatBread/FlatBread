//
//  UserProfileResponseDTO.swift
//  FlatBread
//
//  Created by hwan on 11/6/25.
//

import Foundation


// MARK: 다른사람 과 내 프로필 구조는 같은 구조로 받아온다.
struct UserProfileResponseDTO {
    let userID: String?
    let email: String?
    let nick: String?
    let profileImage: String?
    let phoneNum: String?
    let gender: String?
    let birthDay: String?
    let info1: String?
    let info2: String?
    let info3: String?
    let info4: String?
    let info5: String?
    let followers: [CreatorResponseDTO]
    let following: [CreatorResponseDTO]
    let postIDList: [String]
    
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case email, nick, profileImage, phoneNum, gender, birthDay, info1, info2, info3, info4, info5, followers, following
        case postIDList = "posts"
    }
}

nonisolated extension UserProfileResponseDTO: Decodable { }
