//
//  EditProfileView.swift
//  FlatBread
//
//  Created by 김민성 on 11/13/25.
//

import SwiftUI

struct EditProfileView: View {
    @State var userProfile: UserProfileResponseDTO

    var body: some View {
        Form {
            Text("닉네임: \(userProfile.nick ?? "")")
            Text("생년월일: \(userProfile.birthDay ?? "")")
        }
        .navigationTitle("프로필 수정")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    @Previewable @State var dummyProfile = UserProfileResponseDTO.dummy
    EditProfileView(userProfile: dummyProfile)
}
