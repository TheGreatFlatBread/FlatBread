//
//  OnBoardingViewModel.swift
//  FlatBread
//
//  Created by andev on 11/23/25.
//

import Foundation
import SwiftUI
import Combine
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

@MainActor
final class OnBoardingViewModel: ObservableObject {
    // 타입
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

    // 입력 값
    @Published var nick: String = ""
    @Published var phoneNum: String = ""
    @Published var birthDate: Date = Date()
    @Published var profileImageData: Data? = nil
    @Published var gender: GenderOption = .other

    // 이미지 상태
    @Published var processedImageData: Data? = nil
    @Published var isImageValid: Bool = true
    @Published var previewImageData: Data? = nil
    @Published var isProcessingImage: Bool = false

    // UI 상태
    @Published var isUploading: Bool = false
    @Published var uploadProgress: Double = 0
    @Published var errorMessage: String? = nil
    @Published var shouldShowOnboarding: Bool = true

    // 작업(Task)
    private var imagePreprocessTask: Task<Void, Never>? = nil

    private static let birthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    private static let forbiddenNickCharacters = CharacterSet(charactersIn: ".,?*\\-@+^${}()|[]\\")
    private static let phoneRegexPattern = "^[0-9]{9,12}$"

    var canSubmit: Bool {
        let nickOK = !nick.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let phoneOK = phoneNum.isEmpty || phoneNum.range(of: Self.phoneRegexPattern, options: .regularExpression) != nil
        let containsInvalidNick = !validateNick(nick)
        let imageOK = isImageValid
        return nickOK && phoneOK && !containsInvalidNick && !isUploading && imageOK
    }

    // Actions
    func setProfileImage(data: Data?) {
        profileImageData = data
        isProcessingImage = data != nil

        // Cancel any existing processing task before starting new work
        imagePreprocessTask?.cancel()

        guard let data = data else {
            isProcessingImage = false
            previewImageData = nil
            processedImageData = nil
            isImageValid = true
            return
        }

        imagePreprocessTask = Task(priority: .background) { [weak self] in
            guard let self = self else { return }
            defer { Task { @MainActor in self.isProcessingImage = false } }
            let preview: Data? = autoreleasepool { [weak self] in
                guard let self = self else { return nil }
                if let cg = self.decodeCGImage(from: data) {
                    return self.makeThumbnailData(from: cg, maxSide: 200)
                }
                return nil
            }
            try? Task.checkCancellation()
            let preprocessed: Data? = autoreleasepool { [weak self] in
                guard let self = self else { return nil }
                return self.preprocessImageData(data)
            }
            try? Task.checkCancellation()
            await MainActor.run {
                self.previewImageData = preview
                self.processedImageData = preprocessed
                self.isImageValid = (preprocessed != nil)
                self.isProcessingImage = false
            }
        }
    }

    // 검증
    func validateNick(_ nick: String) -> Bool {
        let trimmed = nick.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        // Check no whitespace inside
        if trimmed.rangeOfCharacter(from: .whitespacesAndNewlines) != nil {
            return false
        }
        // Exclude characters: [.,?*\-@+^${}()|\[\]\\]
        if trimmed.rangeOfCharacter(from: Self.forbiddenNickCharacters) != nil {
            return false
        }
        return true
    }

    func sanitizedNick(_ nick: String) -> String {
        nick.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func prepareProfileImageData(_ data: Data?) -> Data? {
        guard let data = data else { return nil }
        return preprocessImageData(data)
    }

    // 이미지 처리 (Nonisolated 헬퍼)
    nonisolated private func decodeCGImage(from data: Data) -> CGImage? {
        let cfData = data as CFData
        guard let source = CGImageSourceCreateWithData(cfData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    nonisolated private func resizedCGImage(_ image: CGImage, maxSide: CGFloat) -> CGImage? {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let aspectRatio = width / height
        var newSize: CGSize
        if width > height {
            newSize = CGSize(width: maxSide, height: maxSide / aspectRatio)
        } else {
            newSize = CGSize(width: maxSide * aspectRatio, height: maxSide)
        }

        guard let colorSpace = image.colorSpace else { return nil }
        guard let context = CGContext(
            data: nil,
            width: Int(newSize.width),
            height: Int(newSize.height),
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: image.bitmapInfo.rawValue
        ) else { return nil }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(origin: .zero, size: newSize))
        return context.makeImage()
    }

    nonisolated private func jpegData(from image: CGImage, quality: CGFloat) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        let options = [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
        CGImageDestinationAddImage(destination, image, options)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }

    nonisolated private func isPNG(_ data: Data) -> Bool {
        let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47]
        guard data.count >= 4 else { return false }
        let header = [data[0], data[1], data[2], data[3]]
        return header == pngSignature
    }

    private func makeThumbnailData(from cgImage: CGImage, maxSide: CGFloat) -> Data? {
        guard let resized = resizedCGImage(cgImage, maxSide: maxSide) else { return nil }
        return jpegData(from: resized, quality: 0.5)
    }

    nonisolated func preprocessImageData(_ data: Data) -> Data? {
        guard let image = decodeCGImage(from: data) else { return nil }

        // Constants
        let maxSize: Int = 200_000 // 200KB
        let preferredMaxSize: Int = 100_000 // 100KB preferred

        // Early return if PNG and already small enough
        if isPNG(data) && data.count <= maxSize {
            return data
        }

        // Try resizing with fixed quality 0.8 at various sizes (reduced steps)
        let resizeSteps: [CGFloat] = [800, 600, 400]
        var bestData: Data? = nil
        var lastResizedImage: CGImage? = image

        for maxSide in resizeSteps {
            if let resized = resizedCGImage(image, maxSide: maxSide) {
                lastResizedImage = resized
                if let compressedData = jpegData(from: resized, quality: 0.8) {
                    if compressedData.count <= preferredMaxSize {
                        return compressedData
                    }
                    if compressedData.count <= maxSize {
                        bestData = compressedData
                    }
                }
            }
        }

        // If none met criteria by resizing at quality 0.8, try quality compression on smallest resized or original if no resizing (reduced qualities)
        if let imageToCompress = lastResizedImage {
            let qualities: [CGFloat] = [0.6, 0.4, 0.2]
            for quality in qualities {
                if let compressedData = jpegData(from: imageToCompress, quality: quality) {
                    if compressedData.count <= preferredMaxSize {
                        return compressedData
                    }
                    if compressedData.count <= maxSize {
                        bestData = compressedData
                    }
                }
            }
        }

        if let bestData = bestData {
            return bestData
        }

        return nil
    }

    // DTO / 포맷팅
    private func formattedBirthDay() -> String? {
        Self.birthFormatter.string(from: birthDate)
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

    // 네트워킹
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

        let processedImageData = self.processedImageData
        if profileImageData != nil && processedImageData == nil {
            isUploading = false
            errorMessage = "프로필 이미지는 PNG 또는 JPEG 형식이어야 하며 최대 크기는 200KB를 초과할 수 없습니다."
            return false
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
