//
//  CreateMoinViewModel.swift
//  FlatBread
//
//  Created by andev on 11/14/25.
//

import SwiftUI
import Combine
import CoreLocation

@MainActor
final class CreateMoimViewModel: ObservableObject {

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
    @Published var categories: [MoimCategory] = .dummy10
    @Published var selectedCategory: MoimCategory? = nil
    @Published var isFree: Bool = true
    @Published var priceText: String = ""      // 유료일 때만 사용(숫자 문자열)

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
        (dto.title?.isEmpty == false)
        && (dto.content?.isEmpty == false)
        && (dto.category?.isEmpty == false)
        && (dto.price ?? 0) >= 0
    }

    func selectCategory(_ cat: MoimCategory) {
        selectedCategory = cat
        dto.category = cat.name
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

    // 임시 업로드 액션(동작 확인용)
    func createTapped() {
        print("--- CREATE MOIM DTO ---")
        print("title:", dto.title ?? "nil")
        print("category:", dto.category ?? "nil")
        print("price:", dto.price ?? -1)
        print("lat/lon:", dto.latitude, dto.longitude)
        print("content:", dto.content ?? "nil")
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
