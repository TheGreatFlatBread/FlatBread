//
//  NaverMapView.swift
//  FlatBread
//
//  Created by 김민성 on 11/7/25.
//

import Combine
import NMapsMap
import NMapsGeometry
import SwiftUI

struct NaverMapView: UIViewRepresentable {
    
    @Binding var cameraPosition: NMGLatLng
    @Binding var markers: [MoimMarker]
    @Binding var focusingPlaceID: String?
    
    @State(initialValue: Coordinator())
    private var coordinator: Coordinator
    
    init(
        coordinate: Binding<NMGLatLng>,
        markers: Binding<[MoimMarker]>,
        focusingPlaceID: Binding<String?>
    ) {
        self._cameraPosition = coordinate
        self._markers = markers
        self._focusingPlaceID = focusingPlaceID
    }
    
    func makeUIView(context: Context) -> NMFMapView {
        let naverMapView = NMFMapView()
        let cameraUpdate = NMFCameraUpdate(scrollTo: cameraPosition)
        naverMapView.moveCamera(cameraUpdate)
        return naverMapView
    }
    
    func updateUIView(_ uiView: NMFMapView, context: Context) {
        let cameraUpdate = NMFCameraUpdate(scrollTo: cameraPosition)
        cameraUpdate.animation = .fly
        cameraUpdate.animationDuration = 0.8
        
        markers.forEach {
            $0.mapView = uiView
            $0.touchHandler = { overlay in
                guard let moimMarker = overlay as? MoimMarker else { return false }
                cameraPosition = moimMarker.position
                focusingPlaceID = moimMarker.id
                return true
            }
        }
        
        uiView.moveCamera(cameraUpdate)
    }
    
}

#Preview {
    @Previewable @State var coordinate: NMGLatLng = .init(lat: 37.517677, lng: 126.886442)
    @Previewable @State var markers: [MoimMarker] = Moim.makeSample()
        .map { $0.asMarker }
    @Previewable @State var currentPlaceID: String? = nil
    NaverMapView(coordinate: $coordinate, markers: $markers, focusingPlaceID: $currentPlaceID)
}
