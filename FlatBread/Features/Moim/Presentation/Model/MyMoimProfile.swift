//
//  MyMoimProfile.swift
//  FlatBread
//
//  Created by 서준일 on 11/28/25.
//

import Foundation

struct MyMoimProfile: Codable {
    let userID: String
    let nick: String
    let postIDLists: [String]
    
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case nick, postIDLists
    }
}

extension UserProfileResponseDTO {
    
    var asMyMoimProfile: MyMoimProfile? {
        guard let userID = userID else { return nil }
        return MyMoimProfile(
            userID: userID,
            nick: nick ?? "",
            postIDLists: postIDList
        )
    }
}
