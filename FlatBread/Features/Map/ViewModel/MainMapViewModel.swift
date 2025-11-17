//
//  MainMapViewModel.swift
//  FlatBread
//
//  Created by 김민성 on 11/16/25.
//

import Combine
import Foundation
import NMapsMap
import NMapsGeometry

final class MainMapViewModel: ObservableObject {
    @Published var coordinate: NMGLatLng
    @Published var searchText: String = ""
    @Published var categories: [MainMapCategoryUIModel] = Category.allCases.map {
        MainMapCategoryUIModel(name: $0.rawValue, isSelected: true)
    }
    @Published var focusingPlaceID: String? = nil
    @Published var nearbyMoims: [MoimMapUIModel] = []
    @Published var markers: [MoimMarker] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init(coordinate: NMGLatLng) {
        self.coordinate = coordinate
        
        $categories
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                Task { await self.requestNearbyMoimList() }
            }
            .store(in: &cancellables)
    }
    
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    
    func requestNearbyMoimList() async {
        do {
            let fetchResults = try await networkService.request(
                PostRouter.searchGeolocationPostList(
                    // 뒤에 추가된 배열은 카테고리 확정되기 전에 입력한 데이터들.
                    category: categories.filter(\.isSelected).map(\.name) + ["sports", "performance", "운동", "사교/인맥"],
                    longitude: "\(coordinate.lng)",
                    latitude: "\(coordinate.lat)",
                    maxDistance: "100000",
                    order_by: .distance,
                    sort_by: .asc
                ),
                responseType: PostGeoSearchListResponseDTO.self,
                interceptorType: .networkWithToken
            ).data
            nearbyMoims = fetchResults.compactMap(\.toMoimMapUIModel)
            markers.forEach { $0.mapView = nil }
            markers = fetchResults.map(\.asMoimMarker)
        } catch {
            print(error.localizedDescription)
        }
    }
    
}

extension MainMapViewModel {
    
    enum Category: String, CaseIterable {
        case exerciseSports = "운동/스포츠"
        case selfImprovement = "자기계발"
        case humanitiesBooksWriting = "인문학/책/글"
        case culturePerformancesFestivals = "문화/공연/축제"
        case craftsMaking = "공예/만들기"
        case volunteerWork = "봉사활동"
        case carsBikes = "차/바이크"
        case watchingSports = "스포츠관람"
        case cookingManufacturing = "요리/제조"
        case foreignLanguage = "외국/언어"
        case outdoorTravel = "아웃도어/여행"
        case industryJobRole = "업종/직무"
        case musicInstruments = "음악/악기"
        case danceBallet = "댄스/무용"
        case socialNetworking = "사교/인맥"
        case photographyVideo = "사진/영상"
        case gamesEntertainment = "게임/오락"
        case pets = "반려동물"
    }
    
}


extension PostResponseDTO {
    var asMoimMarker: MoimMarker {
        .init(
            id: self.post_id!,
            position: self.geolocation?.asNMGLatLng ?? NMGLatLng.defaultValue
        )
    }
}


extension NMGLatLng {
    // 새싹 영등포
    static var defaultValue: NMGLatLng = .init(lat: 126.886442, lng: 37.517677)
}


extension GeoLocationResponseDTO {
    var asNMGLatLng: NMGLatLng? {
        guard let latitude, let longitude else { return nil }
        return .init(lat: latitude, lng: longitude)
    }
}
