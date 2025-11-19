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

class MainMapViewModel: ObservableObject {
    @Published var coordinate: NMGLatLng
    @Published var searchText: String = ""
    @Published var categories: [MainMapCategoryUIModel] = MoimCategory.allCases.map {
        MainMapCategoryUIModel(category: $0, isSelected: true)
    }
    private var selectedCategoriesPublisher: AnyPublisher<[MoimCategory], Never> {
        $categories
            .map { $0.filter(\.isSelected).map(\.category) }
            .eraseToAnyPublisher()
    }
    @Published var focusingPlaceID: String? = nil
    @Published var nearbyMoims: [MoimMapUIModel] = []
    @Published private var allMoimSearchResult: [MoimSearchResultUIModel] = []
    @Published var moimSearchResult: [MoimSearchResultUIModel] = []
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
            
        $allMoimSearchResult
            .combineLatest(selectedCategoriesPublisher)
            .map { (searchResult, selectedCategories) in
                return searchResult.filter { selectedCategories.contains($0.category) }
            }.eraseToAnyPublisher()
            .assign(to: \.moimSearchResult, on: self)
            .store(in: &cancellables)
        
        $searchText
            .removeDuplicates(by: {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
                == $1.trimmingCharacters(in: .whitespacesAndNewlines)
            })
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                guard let self else { return }
                Task { await self.searchMoim(searchText) }
            }
            .store(in: &cancellables)
    }
    
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    
    func requestNearbyMoimList() async {
        do {
            let fetchResults = try await networkService.request(
                PostRouter.searchGeolocationPostList(
                    // 뒤에 추가된 배열은 카테고리 확정되기 전에 입력한 데이터들.
                    category: categories.map(\.category.rawValue) + ["sports", "performance", "운동", "사교/인맥"],
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
    
    func searchMoim(_ query: String) async {
        let selectedCategories = categories
            .filter(\.isSelected)
            .map(\.category.rawValue)
        
        do {
            allMoimSearchResult = try await networkService.request(
                PostRouter.searchPostTitle(
                    title: query,
                    category: selectedCategories
                ),
                responseType: PostTitleSearchListResponseDTO.self
            )
            .data
            .compactMap(\.asSearchResultUIModel)
            
        } catch {
            print(error.localizedDescription)
        }
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


final class MainMapViewMockModel: MainMapViewModel {
    
    override func requestNearbyMoimList() async {
        return
    }
    
}
