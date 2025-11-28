//
//  EditProfileViewModel.swift
//  FlatBread
//
//  Created by andev on 11/28/25.
//

import SwiftUI
import Combine
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

@MainActor
final class EditProfileViewModel: ObservableObject {
    // Nested types (mirror OnBoardingViewModel)
    enum GenderOption: String, CaseIterable, Identifiable {
        case male, female, other
        var id: String { rawValue }
        var description: String {
            switch self {
            case .male: return "남성"
            case .female: return "여성"
            case .other: return "기타"
            }
        }
    }

    // Existing profile
    let existingProfile: UserProfileResponseDTO

    // Inputs (mirror names used in EditProfileView)
    @Published var nickname: String = ""
    @Published var phone: String = ""
    @Published var birth: Date = Date()
    @Published var gender: GenderOption = .other

    // Image state
    @Published var previewImageData: Data? = nil
    @Published var processedImageData: Data? = nil
    @Published var isImageValid: Bool = true
    @Published var isProcessingImage: Bool = false

    // UI state
    @Published var isUploading: Bool = false
    @Published var uploadProgress: Double = 0
    @Published var errorMessage: String? = nil

    // Task
    private var imagePreprocessTask: Task<Void, Never>? = nil

    // Init with existing profile DTO
    init(existingProfile: UserProfileResponseDTO) {
        self.existingProfile = existingProfile

        // Pre-fill fields
        self.nickname = existingProfile.nick ?? ""
        self.phone = existingProfile.phoneNum ?? ""
        if let birthStr = existingProfile.birthDay, let date = Self.birthFormatter.date(from: birthStr) {
            self.birth = date
        }
        if let genderRaw = existingProfile.gender, let g = GenderOption(rawValue: genderRaw) {
            self.gender = g
        } else {
            self.gender = .other
        }
    }

    private static let birthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let forbiddenNickCharacters = CharacterSet(charactersIn: ".,?*\\-@+^${}()|[]\\")
    private static let phoneRegexPattern = "^[0-9]{9,12}$"

    var canSubmit: Bool {
        let nickOK = !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let phoneOK = phone.isEmpty || phone.range(of: Self.phoneRegexPattern, options: .regularExpression) != nil
        let containsInvalidNick = !validateNick(nickname)
        let imageOK = isImageValid
        return nickOK && phoneOK && !containsInvalidNick && !isUploading && imageOK
    }

    // MARK: - Actions
    func setProfileImage(data: Data?) {
        isProcessingImage = (data != nil)
        imagePreprocessTask?.cancel()

        guard let data = data else {
            isProcessingImage = false
            previewImageData = nil
            processedImageData = nil
            isImageValid = true
            return
        }

        imagePreprocessTask = Task(priority: .background) { [weak self] in
            guard let self else { return }
            defer { Task { @MainActor in self.isProcessingImage = false } }

            let preview: Data? = autoreleasepool { [weak self] in
                guard let self else { return nil }
                if let cg = self.decodeUprightThumbnail(from: data, maxPixel: 200) {
                    return self.jpegData(from: cg, quality: 0.5)
                }
                return nil
            }
            try? Task.checkCancellation()
            let preprocessed: Data? = autoreleasepool { [weak self] in
                guard let self else { return nil }
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

    // MARK: - Validation
    func validateNick(_ nick: String) -> Bool {
        let trimmed = nick.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if trimmed.rangeOfCharacter(from: .whitespacesAndNewlines) != nil { return false }
        if trimmed.rangeOfCharacter(from: Self.forbiddenNickCharacters) != nil { return false }
        return true
    }

    private func sanitizedNick(_ nick: String) -> String { nick.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func formattedBirthDay() -> String? { Self.birthFormatter.string(from: birth) }

    // MARK: - Image helpers (nonisolated)
    nonisolated private func decodeCGImage(from data: Data) -> CGImage? {
        let cfData = data as CFData
        guard let source = CGImageSourceCreateWithData(cfData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    nonisolated private func decodeUprightThumbnail(from data: Data, maxPixel: CGFloat) -> CGImage? {
        let cfData = data as CFData
        guard let source = CGImageSourceCreateWithData(cfData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxPixel),
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
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
        guard let image = decodeUprightThumbnail(from: data, maxPixel: 2000) ?? decodeCGImage(from: data) else { return nil }
        let maxSize: Int = 200_000
        let preferredMaxSize: Int = 100_000
        if isPNG(data) && data.count <= maxSize { return data }
        let resizeSteps: [CGFloat] = [800, 600, 400]
        var bestData: Data? = nil
        var lastResizedImage: CGImage? = image
        for maxSide in resizeSteps {
            if let resized = resizedCGImage(image, maxSide: maxSide) {
                lastResizedImage = resized
                if let compressedData = jpegData(from: resized, quality: 0.8) {
                    if compressedData.count <= preferredMaxSize { return compressedData }
                    if compressedData.count <= maxSize { bestData = compressedData }
                }
            }
        }
        if let imageToCompress = lastResizedImage {
            let qualities: [CGFloat] = [0.6, 0.4, 0.2]
            for quality in qualities {
                if let compressedData = jpegData(from: imageToCompress, quality: quality) {
                    if compressedData.count <= preferredMaxSize { return compressedData }
                    if compressedData.count <= maxSize { bestData = compressedData }
                }
            }
        }
        if let bestData { return bestData }
        return nil
    }

    // MARK: - Submit
    func submit() async {
        guard canSubmit else { return }
        isUploading = true
        uploadProgress = 0
        errorMessage = nil

        let cleanNick = sanitizedNick(nickname)
        guard validateNick(cleanNick) else {
            isUploading = false
            errorMessage = "닉네임은 공백 없이 입력해야 하며, 특수 문자는 사용할 수 없습니다."
            return
        }

        // If user selected an image but preprocessing failed
        if previewImageData != nil && processedImageData == nil {
            isUploading = false
            errorMessage = "프로필 이미지는 PNG 또는 JPEG 형식이어야 하며 최대 크기는 200KB를 초과할 수 없습니다."
            return
        }

        let requestDTO = UserProfileUpdateDTO(
            nick: cleanNick.isEmpty ? nil : cleanNick,
            phoneNum: phone.isEmpty ? nil : phone,
            birthDay: formattedBirthDay(),
            profile: processedImageData,
            gender: gender.rawValue,
            info1: existingProfile.info1,
            info2: existingProfile.info2,
            info3: existingProfile.info3,
            info4: existingProfile.info4,
            info5: existingProfile.info5
        )

        let networkService = NetworkServiceFactory.shared.makeNetworkService()
        do {
            _ = try await networkService.upload(
                MultipartRouter.updateProfile(request: requestDTO),
                responseType: UserProfileResponseDTO.self,
                progress: { [weak self] progress in
                    Task { @MainActor in self?.uploadProgress = progress }
                }
            )
            isUploading = false
        } catch {
            isUploading = false
            errorMessage = error.localizedDescription
        }
    }
}
