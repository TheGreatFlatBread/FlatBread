//
//  OnBoardingViewModel.swift
//  FlatBread
//
//  Created by andev on 11/23/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class OnBoardingViewModel: ObservableObject {
    enum GenderOption: String, CaseIterable, Identifiable {
        case male, female, other
        var id: String { rawValue }
        var display: String {
            switch self {
            case .male: return "남성"
            case .female: return "여성"
            case .other: return "기타"
            }
        }
    }

    // Inputs
    @Published var nick: String = ""
    @Published var phoneNum: String = ""
    @Published var birthDate: Date = Date()
    @Published var profileImageData: Data? = nil
    @Published var gender: GenderOption = .other

    // State
    @Published var isUploading: Bool = false
    @Published var uploadProgress: Double = 0
    @Published var errorMessage: String? = nil
    @Published var shouldShowOnboarding: Bool = true

    var canSubmit: Bool {
        let nickOK = !nick.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let phoneOK = phoneNum.isEmpty || phoneNum.range(of: "^[0-9]{9,12}$", options: .regularExpression) != nil
        return nickOK && phoneOK && !isUploading
    }

    func setProfileImage(data: Data?) {
        profileImageData = data
    }

    private func formattedBirthDay() -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: birthDate)
    }

    private var dto: UserProfileUpdateDTO {
        UserProfileUpdateDTO(
            nick: nick.isEmpty ? nil : nick,
            phoneNum: phoneNum.isEmpty ? nil : phoneNum,
            birthDay: formattedBirthDay(),
            profile: profileImageData,
            gender: gender.rawValue,
            info1: "true",
            info2: nil,
            info3: nil,
            info4: nil,
            info5: nil
        )
    }

    func checkOnboardingNeeded() async {
        let networkService = NetworkServiceFactory.shared.makeNetworkService()
        do {
            let response = try await networkService.request(
                UserRouter.getMeProfile,
                responseType: UserProfileResponseDTO.self,
                interceptorType: .networkWithToken
            )
            shouldShowOnboarding = (response.info1 == nil)
        } catch {
            shouldShowOnboarding = true
        }
    }

    func submit() async -> Bool {
        guard canSubmit else { return false }
        isUploading = true
        uploadProgress = 0
        errorMessage = nil

        let networkService = NetworkServiceFactory.shared.makeNetworkService()
        do {
            _ = try await networkService.upload(
                MultipartRouter.updateProfile(request: dto),
                responseType: UserProfileResponseDTO.self,
                progress: { [weak self] progress in
                    Task { @MainActor in
                        self?.uploadProgress = progress
                    }
                }
            )
            isUploading = false
            shouldShowOnboarding = false
            return true
        } catch {
            isUploading = false
            errorMessage = error.localizedDescription
            return false
        }
    }
}
