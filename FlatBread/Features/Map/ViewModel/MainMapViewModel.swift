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
import CoreLocation

class MainMapViewModel: ObservableObject {
    @Published var coordinate: NMGLatLng
    @Published var searchText: String = ""
    @Published var categories: [MainMapCategoryUIModel] = MoimCategory.allCases.map {
        MainMapCategoryUIModel(category: $0, isSelected: true)
    }
    @Published var userLocation: NMGLatLng?
    private var selectedCategoriesPublisher: AnyPublisher<[MoimCategory], Never> {
        $categories
            .map { $0.filter(\.isSelected).map(\.category) }
            .eraseToAnyPublisher()
    }
    @Published var focusingPlaceID: String? = nil
    @Published var nearbyMoims: [MoimMapUIModel] = []
    @Published private var allMoimSearchResult: [MoimSearchResultUIModel] = []
    @Published var moimSearchResult: [MoimSearchResultUIModel] = []
    @Published var markers: [NMFMarker] = []
    @Published var zoomLevel: Double = 12.0
    @Published var cameraUpdateTrigger: UUID?

    // 카드 리스트 표시 관련
    @Published var isCardListVisible: Bool = false
    @Published var visibleMoims: [MoimMapUIModel] = []
    @Published var scrollToMoimTrigger: UUID?

    // 클러스터링 전의 원본 모임 마커들
    private var moimMarkers: [MoimMarker] = []
    // 클러스터링 매니저
    private let clusteringManager = ClusteringManager()

    let locationManager = LocationManager()

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

        // LocationManager의 currentLocation을 구독하여 userLocation 업데이트
        locationManager.$currentLocation
            .compactMap { $0 }
            .map { location in
                NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
            }
            .assign(to: \.userLocation, on: self)
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

            // 기존 마커 제거
            markers.forEach { $0.mapView = nil }

            // 원본 모임 마커 생성 및 저장
            moimMarkers = fetchResults.map(\.asMoimMarker)

            // 초기에는 클러스터링 없이 원본 마커 표시
            markers = moimMarkers
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

    func moveToMyLocation() {
        print(#function)
        guard let userLocation = userLocation else { return }
        print(#function, userLocation)
        coordinate = userLocation
        cameraUpdateTrigger = UUID()
    }

    /// 지도의 projection을 사용하여 마커 클러스터링 수행 (화면에 보이는 마커만)
    /// - Parameters:
    ///   - mapView: 네이버 지도 뷰
    ///   - projection: 지도 좌표를 화면 좌표로 변환하는 projection
    func updateClusteringMarkers(mapView: NMFMapView, projection: NMFProjection) {
        // 기존 마커들 제거
        markers.forEach { $0.mapView = nil }

        // 화면 영역 가져오기 (20% padding 추가)
        let visibleBounds = mapView.contentBounds.expanded(by: 0.2)

        // 화면 내 마커만 필터링
        let visibleMarkers = moimMarkers.filter { marker in
            visibleBounds.hasPoint(marker.position)
        }

        // 클러스터링 수행 (화면 내 마커만)
        let clusters = clusteringManager.cluster(
            markers: visibleMarkers,
            zoomLevel: zoomLevel,
            projection: projection
        )

        // 클러스터 결과를 마커로 변환
        var newMarkers: [NMFMarker] = []

        for cluster in clusters {
            if cluster.count == 1 {
                // 마커가 1개만 있으면 개별 마커로 표시
                newMarkers.append(cluster.markers[0])
            } else {
                // 2개 이상이면 클러스터 마커로 표시
                let clusterMarker = ClusterMarker(
                    moimMarkers: cluster.markers,
                    position: cluster.centerPosition
                )
                newMarkers.append(clusterMarker)
            }
        }

        markers = newMarkers
    }

    /// 현재 화면에 보이는 마커들에 해당하는 모임만 필터링하여 카드 리스트 표시
    /// - Parameter mapView: 네이버 지도 뷰
    func showCardListForVisibleMarkers(mapView: NMFMapView) {
        // 지도의 bounds 가져오기
        let bounds = mapView.contentBounds

        // 화면 내에 있는 모임만 필터링
        visibleMoims = nearbyMoims.filter { moim in
            bounds.hasPoint(moim.location)
        }

        isCardListVisible = true

        // 카드 리스트가 표시된 후 포커스된 모임으로 스크롤
        if let focusedID = focusingPlaceID,
           visibleMoims.contains(where: { $0.id == focusedID }) {
            // 약간의 지연 후 스크롤 트리거 (애니메이션 완료 대기)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.scrollToMoimTrigger = UUID()
            }
        }
    }

    /// 카드 리스트 숨김
    func hideCardList() {
        isCardListVisible = false
        visibleMoims = []
        focusingPlaceID = nil
    }

    /// 특정 모임 위치로 카메라 이동
    /// - Parameter moimID: 이동할 모임 ID
    func moveCameraToMoim(moimID: String) {
        if let selectedMoim = nearbyMoims.first(where: { $0.id == moimID }) {
            focusingPlaceID = moimID
            coordinate = selectedMoim.location
            cameraUpdateTrigger = UUID()

            // 카드 리스트에서 해당 카드로 스크롤
            if isCardListVisible {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.scrollToMoimTrigger = UUID()
                }
            }
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

// MARK: - NMGLatLngBounds Extension
extension NMGLatLngBounds {
    /// 경계를 지정된 비율만큼 확장
    /// - Parameter ratio: 확장 비율 (0.2 = 20% 확장)
    /// - Returns: 확장된 경계
    func expanded(by ratio: Double) -> NMGLatLngBounds {
        let latDiff = northEastLat - southWestLat
        let lngDiff = northEastLng - southWestLng

        let latPadding = latDiff * ratio
        let lngPadding = lngDiff * ratio

        let expandedSouthWest = NMGLatLng(
            lat: southWestLat - latPadding,
            lng: southWestLng - lngPadding
        )

        let expandedNorthEast = NMGLatLng(
            lat: northEastLat + latPadding,
            lng: northEastLng + lngPadding
        )

        return NMGLatLngBounds(southWest: expandedSouthWest, northEast: expandedNorthEast)
    }
}
