//
//  MainMapView.swift
//  FlatBread
//
//  Created by 김민성 on 11/6/25.
//

import SwiftUI
import NMapsMap
import NMapsGeometry

struct MainMapView: View {
    
    @State private var coordinate: NMGLatLng
    @State private var searchText: String = ""
    @State private var moims: [MoimInMainMap] = []
    @State private var markers: [MoimMarker] = []
    @State private var focusingPlaceID: String? = nil
    
    init(initialPosition: NMGLatLng = .init(lat: 37.517677, lng: 126.886442)) {
        self.coordinate = initialPosition
    }
    
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            ZStack {
                NaverMapView(coordinate: $coordinate, markers: $markers, focusingPlaceID: $focusingPlaceID)
                .ignoresSafeArea(.all)
                
                VStack {
                    MainMapSearchBar(searchText: $searchText)
                    Spacer()
                }
                .background(
                    LinearGradient(
                        colors: [.white.opacity(0.95), .white.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 150)
                    .edgesIgnoringSafeArea(.top)
                    .allowsHitTesting(false),
                    alignment: .top
                )
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(moims) { moim in
                                MoimCardView(
                                    moim: moim,
                                    isFocusing: focusingPlaceID == moim.id
                                )
                                .onTapGesture {
                                    handleCardClick(moimID: moim.id)
                                }
                                .id(moim.id)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                        .padding(.top, 1.5)
                    }
                    .background(.clear)
                    .onChange(of: focusingPlaceID) { _, newValue in
                        guard let currentPlaceID  = newValue else { return }
                        withAnimation {
                            scrollViewProxy.scrollTo(currentPlaceID, anchor: .center)
                        }
                    }
                }
            }
        }
        .onAppear {
            moims = MoimInMainMap.makeSample()
            markers = moims.map({
                return MoimMarker(id: $0.id, position: NMGLatLng(from: $0.location))
            })
        }
    }
    
    func handleCardClick(moimID: String) {
        if let selectedPosition = moims.filter({ $0.id == moimID }).first {
            focusingPlaceID = moimID
            coordinate = NMGLatLng(from: selectedPosition.location)
        }
        focusingPlaceID = moimID
    }
}

#Preview {
    MainMapView()
}
