//
//  UserProfileUpdateDTO.swift
//  FlatBread
//
//  Created by hwan on 11/5/25.
//

import Foundation

struct UserProfileUpdateDTO {
    let nick: String?
    let phoneNum: String?
    let birthDay: String?
    let profile: Data? // binary image data
    let gender: String?
    let info1: String?
    let info2: String?
    let info3: String?
    let info4: String?
    let info5: String?
}

extension UserProfileUpdateDTO: Encodable { }
