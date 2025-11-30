//
//  FindNearbyMyProfileUIModel.swift
//  FlatBread
//
//  Created by 김민성 on 11/30/25.
//

import Foundation

struct FindNearbyMyProfileUIModel: Equatable {
    let userID: String
    let profileImage: String?
    let nickname: String
}


extension UserProfileResponseDTO {
    
    var asFindNearByUIModel: FindNearbyMyProfileUIModel {
        return .init(
            userID: self.userID ?? "",
            profileImage: self.profileImage,
            nickname: self.nick ?? ""
        )
    }
    
}
