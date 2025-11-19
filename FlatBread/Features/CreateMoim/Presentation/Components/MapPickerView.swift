//
//  MapPickerView.swift
//  FlatBread
//
//  Created by andev on 11/14/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapPickerView: View {
    @Binding var coordinate: CLLocationCoordinate2D
    
    @State private var camera: MapCameraPosition
    
    init(coordinate: Binding<CLLocationCoordinate2D>) {
        _coordinate = coordinate
        _camera = State(initialValue: .region(
            MKCoordinateRegion(
                center: coordinate.wrappedValue,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        ))
    }
    
    var body: some View {
        ZStack {
            Map(position: $camera, interactionModes: [.all])
                .ignoresSafeArea(edges: .horizontal)
                .onMapCameraChange(frequency: .continuous) { ctx in
                    // 중심 좌표를 선택값으로 사용
                    coordinate = ctx.region.center
                }
            
            // 중앙 고정 핀
            Image("map_marker")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 40)
                .shadow(radius: 4)
                .allowsHitTesting(false)
            
            // 좌표 표시 바
            VStack {
                Spacer()
                HStack {
                    Text(String(format: "위도 %.5f, 경도 %.5f",
                                coordinate.latitude, coordinate.longitude))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.bottom, 8)
            }
            .allowsHitTesting(false)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
