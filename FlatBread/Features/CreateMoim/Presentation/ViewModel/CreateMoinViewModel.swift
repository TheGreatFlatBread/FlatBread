//
//  CreateMoinViewModel.swift
//  FlatBread
//
//  Created by andev on 11/14/25.
//

import SwiftUI
import Combine
import CoreLocation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

@MainActor
final class CreateMoimViewModel: ObservableObject {

    private let networkService = NetworkServiceFactory.shared.makeNetworkService()

    // 서버 전송용 DTO
    @Published var dto = PostUploadRequestDTO(
        category: nil,
        title: nil,
        price: 0,
        content: nil,
        value1: nil, value2: nil, value3: nil, value4: nil, value5: nil,
        value6: nil, value7: nil, value8: nil, value9: nil, value10: nil,
        files: [],
        longitude: 126.9780,   // 서울 시청 근방
        latitude: 37.5665
    )

    // UI 상태
    @Published var categories: [MoimCategory] = MoimCategory.allCases
    @Published var selectedCategory: MoimCategory? = nil
    @Published var isFree: Bool = true
    @Published var priceText: String = ""      // 유료일 때만 사용(숫자 문자열)
    @Published var selectedImageData: Data? = nil
    @Published var isUploading: Bool = false
    @Published var uploadErrorMessage: String? = nil
    
    // 지역 선택 상태
    @Published var selectedRegionName: String? = nil
    
    var allRegions: [String] { RegionData.allRegionNames }

    private let maxUploadFileSizeBytes: Int = 10 * 1024 * 1024 // 10MB

    let titleLimit = 24
    let contentLimit = 500

    var titleBinding: Binding<String> {
        .init(
            get: { self.dto.title ?? "" },
            set: { [weak self] in
                guard let self else { return }
                let trimmed = String($0.prefix(titleLimit))
                dto.title = trimmed.isEmpty ? nil : trimmed
            }
        )
    }

    var contentBinding: Binding<String> {
        .init(
            get: { self.dto.content ?? "" },
            set: { [weak self] in
                guard let self else { return }
                let trimmed = String($0.prefix(contentLimit))
                dto.content = trimmed.isEmpty ? nil : trimmed
            }
        )
    }

    var canSubmit: Bool {
        // 1) 기본 텍스트들
        let t = (dto.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let c = (dto.content ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let hasTitle = !t.isEmpty
        let hasContent = !c.isEmpty
        
        // 2) 카테고리
        let hasCategory = !(dto.category ?? "").isEmpty
        
        // 3) 지역 (시/군/구)
        let hasRegion = selectedRegionName != nil
        
        // 4) 대표 이미지
        let hasImage = selectedImageData != nil
        
        // 5) 가격 조건
        let price = dto.price ?? 0
        let hasValidPrice: Bool = {
            if isFree {
                return price == 0
            } else {
                return price > 0        // 유료면 0원 금지
            }
        }()
        
        return hasTitle
            && hasContent
            && hasCategory
            && hasRegion
            && hasImage
            && hasValidPrice
    }
    
    // 지역 선택 시 DTO에도 반영
    func selectRegionName(_ name: String) {
        selectedRegionName = name
        dto.value1 = name
    }

    func selectCategory(_ cat: MoimCategory) {
        selectedCategory = cat
        dto.category = cat.rawValue
    }

    func toggleFree(_ newValue: Bool) {
        isFree = newValue
        if newValue {
            dto.price = 0
            priceText = ""
        }
    }

    func commitPriceFromText() {
        guard !isFree else {
            dto.price = 0
            return
        }
        // 숫자만 추출해서 Int로 저장 (원 단위)
        let digits = priceText.filter(\.isNumber)
        dto.price = Int(digits) ?? 0
        priceText = digits.formattedWithWon() // 표시용 포맷
    }

    func updateCoordinate(_ coord: CLLocationCoordinate2D) {
        dto.latitude = coord.latitude
        dto.longitude = coord.longitude
    }
    
    func setSelectedImage(data: Data?) {
        selectedImageData = data
    }
    
    // MARK: - 이미지 크기 검증 및 처리 로직
    private func prepareImageForUpload(_ data: Data, maxBytes: Int = 10 * 1024 * 1024, maxDimension: CGFloat = 2048) -> Data? {
        // 이미 제한 이하라면 그대로 사용
        if data.count <= maxBytes { return data }

        // 이미지 디코딩
        let cfData = data as CFData
        guard let source = CGImageSourceCreateWithData(cfData, nil) else {
            print("[ImageValidation] Failed to create CGImageSource from data.")
            return nil
        }

        // Helpers
        func makeThumbnail(maxDim: Int) -> CGImage? {
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: maxDim,
                kCGImageSourceCreateThumbnailWithTransform: true
            ]
            return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        }

        func jpegData(from cgImage: CGImage, quality: CGFloat) -> Data? {
            let mutableData = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(mutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
                return nil
            }
            let props: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
            CGImageDestinationAddImage(destination, cgImage, props as CFDictionary)
            guard CGImageDestinationFinalize(destination) else { return nil }
            return mutableData as Data
        }

        let initialMax = Int(maxDimension)
        if let thumb = makeThumbnail(maxDim: initialMax) {
            // 리사이즈된 이미지에 먼저 높은 품질로 시도
            if let resizedData = jpegData(from: thumb, quality: 1.0), resizedData.count <= maxBytes {
                return resizedData
            }

            // 그 다음 단계적으로 품질 낮춤
            let qualities: [CGFloat] = [0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.35, 0.3, 0.25, 0.2, 0.18, 0.15, 0.12, 0.1]
            for q in qualities {
                if let compressed = jpegData(from: thumb, quality: q), compressed.count <= maxBytes {
                    return compressed
                }
            }

            // 해상도를 점진적으로 더 줄이며 압축 재시도
            var currentMax = initialMax
            while currentMax > 800 { // 가장 긴 변이 800px 이하가 되지 않도록
                currentMax = Int(Double(currentMax) * 0.8)
                guard let smaller = makeThumbnail(maxDim: currentMax) else { break }

                if let d = jpegData(from: smaller, quality: 0.9), d.count <= maxBytes {
                    return d
                }
                for q in qualities {
                    if let d = jpegData(from: smaller, quality: q), d.count <= maxBytes {
                        return d
                    }
                }
            }
        } else {
            // Fallback: 썸네일 생성에 실패한 경우, 원본 전체를 압축 시도
            if let full = CGImageSourceCreateImageAtIndex(source, 0, nil) {
                if let d = jpegData(from: full, quality: 0.9), d.count <= maxBytes { return d }
                let qualities: [CGFloat] = [0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.25, 0.2, 0.18, 0.15, 0.12, 0.1]
                for q in qualities {
                    if let d = jpegData(from: full, quality: q), d.count <= maxBytes { return d }
                }
            }
        }

        print("[ImageValidation] Unable to reduce image under the max size (\(maxBytes) bytes).")
        return nil
    }
    
    private func uploadImagesIfNeeded() async throws -> [String] {
        guard let data = selectedImageData else { return [] }
        // 10MB 이하가 되도록 검증: 리사이즈 우선, 필요 시 압축
        guard let preparedData = prepareImageForUpload(data, maxBytes: maxUploadFileSizeBytes) else {
            throw NetworkError.uploadFailed
        }

        let request = ImageUploadRequestDTO(images: [preparedData])
        let router = MultipartRouter.uploadImages(request: request)
        let response = try await networkService.upload(
            router,
            responseType: FileUploadResponseDTO.self,
            interceptorType: .networkWithToken,
            progress: { progress in
                print("upload progress: ", progress)
            }
        )
        return response.files
    }
    
    func submit() async {
        if isFree { dto.price = 0 } else { commitPriceFromText() }

        isUploading = true
        uploadErrorMessage = nil
        defer { isUploading = false }

        do {
            // 대표 이미지 업로드
            if selectedImageData != nil {
                let uploadedURLs = try await uploadImagesIfNeeded()
                dto.files = uploadedURLs
            }

            // 게시글 생성 요청
            let postResponse = try await networkService.request(
                PostRouter.uploadPost(request: dto),
                responseType: PostResponseDTO.self,
                interceptorType: .networkWithToken
            )
            print("[POST CREATED]: \(postResponse)")

            createTapped() // 성공 로그
        } catch {
            print("[CreateMoim] 업로드 또는 생성 실패: \(error)")
            uploadErrorMessage = error.localizedDescription
        }
    }

    // 임시 업로드 액션(동작 확인용)
    func createTapped() {
        print("--- CREATE MOIM DTO ---")
        print("title:", dto.title ?? "nil")
        print("category:", dto.category ?? "nil")
        print("price:", dto.price ?? -1)
        print("lat/lon:", dto.latitude, dto.longitude)
        print("files:", dto.files)
        print("content:", dto.content ?? "nil")
        print("region:", dto.value1 ?? "nil")
        print("-----------------------")
    }
}

// MARK: - Helpers
private extension String {
    func formattedWithWon() -> String {
        guard let int = Int(self) else { return self }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let s = formatter.string(from: NSNumber(value: int)) ?? "\(int)"
        return s
    }
}
