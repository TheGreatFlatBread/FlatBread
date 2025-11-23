//
//  OnBoardingViewModel.swift
//  FlatBread
//
//  Created by andev on 11/23/25.
//

import Foundation
import SwiftUI
import Combine
import UIKit

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
        let containsInvalidNick = !validateNick(nick)
        let imageOK = profileImageData == nil || prepareProfileImageData(profileImageData) != nil
        return nickOK && phoneOK && !containsInvalidNick && !isUploading && imageOK
    }

    func setProfileImage(data: Data?) {
        profileImageData = data
    }

    // MARK: - Private helpers

    func validateNick(_ nick: String) -> Bool {
        let trimmed = nick.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        // Check no whitespace inside
        if trimmed.rangeOfCharacter(from: .whitespacesAndNewlines) != nil {
            return false
        }
        // Exclude characters: [.,?*\-@+^${}()|\[\]\\]
        let forbiddenCharacters = CharacterSet(charactersIn: ".,?*\\-@+^${}()|[]\\")
        if trimmed.rangeOfCharacter(from: forbiddenCharacters) != nil {
            return false
        }
        return true
    }

    func sanitizedNick(_ nick: String) -> String {
        nick.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func prepareProfileImageData(_ data: Data?) -> Data? {
        guard let data = data else { return nil }
        guard let image = UIImage(data: data) else { return nil }

        // Detect PNG or JPEG by header bytes
        let isPNG: Bool = {
            let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47]
            guard data.count >= 4 else { return false }
            let header = [data[0], data[1], data[2], data[3]]
            return header == pngSignature
        }()
        
        // Constants
        let maxSize: Int = 200_000 // 200KB
        let preferredMaxSize: Int = 100_000 // 100KB preferred

        // Early return if PNG and already small enough
        if isPNG && data.count <= maxSize {
            return data
        }

        // Helper to resize UIImage maintaining aspect ratio
        func resizedImage(_ image: UIImage, maxSide: CGFloat) -> UIImage {
            let size = image.size
            let aspectRatio = size.width / size.height
            var newSize: CGSize
            if size.width > size.height {
                newSize = CGSize(width: maxSide, height: maxSide / aspectRatio)
            } else {
                newSize = CGSize(width: maxSide * aspectRatio, height: maxSide)
            }
            let format = UIGraphicsImageRendererFormat.default()
            format.opaque = false
            let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        }

        // Try resizing with fixed quality 0.8 at various sizes
        let resizeSteps: [CGFloat] = [1024, 800, 600, 400]
        var bestData: Data? = nil
        var lastResizedImage = image

        for maxSide in resizeSteps {
            let resized = resizedImage(image, maxSide: maxSide)
            lastResizedImage = resized
            if let compressedData = resized.jpegData(compressionQuality: 0.8) {
                if compressedData.count <= preferredMaxSize {
                    return compressedData
                }
                if compressedData.count <= maxSize {
                    bestData = compressedData
                }
            }
        }

        // If none met criteria by resizing at quality 0.8, try quality compression on smallest resized or original if no resizing
        let imageToCompress = lastResizedImage
        let qualities: [CGFloat] = [0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1]
        for quality in qualities {
            if let compressedData = imageToCompress.jpegData(compressionQuality: quality) {
                if compressedData.count <= preferredMaxSize {
                    return compressedData
                }
                if compressedData.count <= maxSize {
                    bestData = compressedData
                }
            }
        }

        if let bestData = bestData {
            return bestData
        }

        return nil
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

        let cleanNick = sanitizedNick(nick)
        guard validateNick(cleanNick) else {
            isUploading = false
            errorMessage = "닉네임은 공백 없이 입력해야 하며, 특수 문자는 사용할 수 없습니다."
            return false
        }

        var processedImageData: Data? = nil
        if let originalImageData = profileImageData {
            guard let compressed = prepareProfileImageData(originalImageData) else {
                isUploading = false
                errorMessage = "프로필 이미지는 PNG 또는 JPEG 형식이어야 하며 최대 크기는 200KB를 초과할 수 없습니다."
                return false
            }
            processedImageData = compressed
        }

        // Build DTO with sanitized nick and processed image
        let requestDTO = UserProfileUpdateDTO(
            nick: cleanNick.isEmpty ? nil : cleanNick,
            phoneNum: phoneNum.isEmpty ? nil : phoneNum,
            birthDay: formattedBirthDay(),
            profile: processedImageData,
            gender: gender.rawValue,
            info1: "true",
            info2: nil,
            info3: nil,
            info4: nil,
            info5: nil
        )

        let networkService = NetworkServiceFactory.shared.makeNetworkService()
        do {
            _ = try await networkService.upload(
                MultipartRouter.updateProfile(request: requestDTO),
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

