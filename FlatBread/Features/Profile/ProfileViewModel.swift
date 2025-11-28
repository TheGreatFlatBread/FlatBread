//
//  ProfileViewModel.swift
//  FlatBread
//
//  Created by 김민성 on 11/14/25.
//

import Combine
import Foundation

extension UserProfileResponseDTO {
    
    static let profileViewDummy = UserProfileResponseDTO(
        userID: "1234567890abcdefghijklmn",
        email: "abcd@flatbread.com",
        nick: "곰팡이핀플랫브레드",
        profileImage: nil,
        phoneNum: "01012341234",
        gender: "male",
        birthDay: nil,
        info1: nil,
        info2: nil,
        info3: nil,
        info4: nil,
        info5: nil,
        followers: [],
        following: [],
        postIDList: []
    )
    
}

// 내비게이션 경로
enum NavigationRoute: Hashable {
    case profile
    case myMoim
    case makeNewMoim
    case chatList
    case withdraw
}

class ProfileViewModel: ObservableObject {
    
    @Published var myProfile: UserProfileResponseDTO?
    @Published var path: [NavigationRoute] = []
    
    @Published var isLoadingProfile: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var showingAlert: Bool = false
    @Published var profileImageURL: URL? = nil
    
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    
    func requestMyProfile() async {
        do {
            isLoadingProfile = true
            let responseDTO = try await networkService.request(
                UserRouter.getMeProfile,
                responseType: UserProfileResponseDTO.self,
                interceptorType: .networkWithToken
            )
            isLoadingProfile = false
            myProfile = responseDTO
            profileImageURL = responseDTO.profileImage.flatMap { URL(string: $0) }
        } catch {
            isLoadingProfile = false
            alertTitle = "프로필 불러오기 실패"
            alertMessage = error.localizedDescription
            showingAlert = true
            profileImageURL = nil
        }
    }
    
}

/// Preview에서 사용하기 위한 Mock View Model
/// (Preview에서는 네트워크 호출하지 않음.)
final class MockProfileViewModel: ProfileViewModel {
    
    override func requestMyProfile() async {
        myProfile = await Task {
            return UserProfileResponseDTO.profileViewDummy
        }.value
        profileImageURL = myProfile?.profileImage.flatMap { URL(string: $0) }
    }
    
}
