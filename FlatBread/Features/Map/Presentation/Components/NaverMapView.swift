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
    
    @Binding var coordinate: NMGLatLng
    @Binding var markers: [NMFMarker]
    
    func makeUIView(context: Context) -> NMFMapView {
        let naverMapView = NMFMapView()
        let cameraUpdate = NMFCameraUpdate(scrollTo: coordinate)
        naverMapView.moveCamera(cameraUpdate)
        return naverMapView
    }
    
    func updateUIView(_ uiView: NMFMapView, context: Context) {
        let cameraUpdate = NMFCameraUpdate(scrollTo: coordinate)
        cameraUpdate.animation = .fly
        cameraUpdate.animationDuration = 0.8
        markers.forEach { $0.mapView = uiView }
        uiView.moveCamera(cameraUpdate)
    }
    
}

#Preview {
    @Previewable @State var coordinate: NMGLatLng = .init(lat: 37.517677, lng: 126.886442)
    @Previewable @State var markers: [NMFMarker] = []
    NaverMapView(coordinate: $coordinate, markers: $markers)
}
