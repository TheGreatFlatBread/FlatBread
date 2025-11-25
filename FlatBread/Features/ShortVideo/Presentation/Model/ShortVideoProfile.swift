//
//  ShortVideoProfile.swift
//  FlatBread
//
//  Created by 김민성 on 11/25/25.
//

struct ShortVideoProfile: Identifiable {
    let id: String
    let nickname: String
    let profileImage: String?
}


extension UserProfileResponseDTO {
    var asShortVideoProfile: ShortVideoProfile {
        return ShortVideoProfile(
            id: userID ?? "",
            nickname: nick ?? "",
            profileImage: self.profileImage
        )
    }
}
