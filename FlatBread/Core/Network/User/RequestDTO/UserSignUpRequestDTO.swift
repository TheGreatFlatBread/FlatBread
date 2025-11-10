//
//  RequestDTO.swift
//  FlatBread
//
//  Created by hwan on 11/5/25.
//

import Foundation

struct UserSignUpRequestDTO {
    var email: String
    var password: String
    var nick: String
    var phoneNum: String?
    var birthDay: String?
    var gender: String?
    var info1: String?
    var info2: String?
    var info3: String?
    var info4: String?
    var info5: String?
}

extension UserSignUpRequestDTO: Encodable { } 
