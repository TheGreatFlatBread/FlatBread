//
//  NaverMapView.swift
//  FlatBread
//
//  Created by 김민성 on 11/7/25.
//

import NMapsMap
import NMapsGeometry
import SwiftUI

struct NaverMapView: UIViewRepresentable {

    @Binding var cameraPosition: NMGLatLng
    @Binding var markers: [NMFMarker]
    @Binding var focusingPlaceID: String?
    @Binding var userLocation: NMGLatLng?
    @Binding var cameraUpdateTrigger: UUID?
    @Binding var zoomLevel: Double
    @ObservedObject var viewModel: MainMapViewModel

    init(
        coordinate: Binding<NMGLatLng>,
        markers: Binding<[NMFMarker]>,
        focusingPlaceID: Binding<String?>,
        userLocation: Binding<NMGLatLng?>,
        cameraUpdateTrigger: Binding<UUID?>,
        zoomLevel: Binding<Double>,
        viewModel: MainMapViewModel
    ) {
        self._cameraPosition = coordinate
        self._markers = markers
        self._focusingPlaceID = focusingPlaceID
        self._userLocation = userLocation
        self._cameraUpdateTrigger = cameraUpdateTrigger
        self._zoomLevel = zoomLevel
        self.viewModel = viewModel
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> NMFMapView {
        let naverMapView = NMFMapView()
        naverMapView.addCameraDelegate(delegate: context.coordinator)
        let cameraUpdate = NMFCameraUpdate(scrollTo: cameraPosition)
        naverMapView.moveCamera(cameraUpdate)
        return naverMapView
    }
    
    func updateUIView(_ uiView: NMFMapView, context: Context) {
        // cameraUpdateTrigger가 변경된 경우에만 카메라 이동
        if context.coordinator.lastCameraUpdateTrigger != cameraUpdateTrigger {
            context.coordinator.lastCameraUpdateTrigger = cameraUpdateTrigger

            let cameraUpdate = NMFCameraUpdate(scrollTo: cameraPosition)
            cameraUpdate.animation = .fly
            cameraUpdate.animationDuration = 0.8
            uiView.moveCamera(cameraUpdate)
        }

        markers.forEach { marker in
            marker.mapView = uiView

            // MoimMarker인 경우
            if let moimMarker = marker as? MoimMarker {
                marker.touchHandler = { overlay in
                    guard let moimMarker = overlay as? MoimMarker else { return false }
                    self.cameraPosition = moimMarker.position
                    self.focusingPlaceID = moimMarker.id
                    return true
                }
            }
            // ClusterMarker인 경우
            else if let clusterMarker = marker as? ClusterMarker {
                marker.touchHandler = { overlay in
                    guard let clusterMarker = overlay as? ClusterMarker else { return false }
                    // 클러스터의 경계로 카메라 이동
                    let bounds = clusterMarker.calculateBounds()
                    let cameraUpdate = NMFCameraUpdate(fit: bounds, padding: 100)
                    cameraUpdate.animation = .easeIn
                    cameraUpdate.animationDuration = 0.5
                    uiView.moveCamera(cameraUpdate)
                    return true
                }
            }
        }

        // 위치 오버레이 설정
        if let userLocation = userLocation {
            uiView.locationOverlay.location = userLocation
            uiView.locationOverlay.hidden = false
        } else {
            uiView.locationOverlay.hidden = true
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NMFMapViewCameraDelegate {
        var parent: NaverMapView
        private var lastZoomLevel: Double = 0
        private var clusteringWorkItem: DispatchWorkItem?
        var lastCameraUpdateTrigger: UUID?

        init(parent: NaverMapView) {
            self.parent = parent
            self.lastZoomLevel = parent.zoomLevel
            self.lastCameraUpdateTrigger = parent.cameraUpdateTrigger
        }

        func mapView(_ mapView: NMFMapView, cameraDidChangeByReason reason: Int, animated: Bool) {
            let currentZoom = mapView.zoomLevel

            // 줌 레벨이 실제로 변경된 경우에만 처리
            if abs(currentZoom - lastZoomLevel) > 0.1 {
                lastZoomLevel = currentZoom

                // 기존 작업 취소
                clusteringWorkItem?.cancel()

                // 새로운 debouncing 작업 생성
                let workItem = DispatchWorkItem { [weak self] in
                    guard let self = self else { return }

                    DispatchQueue.main.async {
                        self.parent.zoomLevel = currentZoom
                        // 클러스터링 업데이트
                        self.parent.viewModel.updateClusteringMarkers(projection: mapView.projection)
                    }
                }

                clusteringWorkItem = workItem

                // 0.3초 후에 실행 (debouncing)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
            }
        }
    }

}

#Preview {
    @Previewable @State var coordinate: NMGLatLng = .init(lat: 37.517677, lng: 126.886442)
    @Previewable @StateObject var viewModel = MainMapViewMockModel(coordinate: .init(lat: 37.517677, lng: 126.886442))
    @Previewable @State var currentPlaceID: String? = nil
    @Previewable @State var userLocation: NMGLatLng? = .init(lat: 37.517677, lng: 126.886442)
    @Previewable @State var cameraUpdateTrigger: UUID? = nil
    @Previewable @State var zoomLevel: Double = 12.0
    NaverMapView(
        coordinate: $coordinate,
        markers: $viewModel.markers,
        focusingPlaceID: $currentPlaceID,
        userLocation: $userLocation,
        cameraUpdateTrigger: $cameraUpdateTrigger,
        zoomLevel: $zoomLevel,
        viewModel: viewModel
    )
}
