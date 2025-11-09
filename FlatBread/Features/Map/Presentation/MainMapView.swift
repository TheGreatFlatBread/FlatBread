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
                            ForEach(moims) { meeting in
                                MeetingCardView(
                                    meeting: meeting,
                                    isFocusing: focusingPlaceID == meeting.id
                                )
                                .onTapGesture {
                                    handleCardClick(meetingId: meeting.id)
                                }
                                .id(meeting.id)
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
    
    func handleCardClick(meetingId: String) {
        if let selectedPosition = moims.filter({ $0.id == meetingId }).first {
            focusingPlaceID = meetingId
            coordinate = NMGLatLng(from: selectedPosition.location)
        }
        focusingPlaceID = meetingId
    }
}

struct MeetingCardView: View {
    let meeting: MoimInMainMap
    let isFocusing: Bool
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: meeting.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.5)
            }
            .frame(width: 300, height: 200)
            
            LinearGradient(
                colors: [.clear, .black],
                startPoint: .center,
                endPoint: .bottom
            )
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(meeting.category)
                        .font(.system(size: 13))
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.brown.opacity(0.8))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Text("\(meeting.currentMembers)/\(meeting.maxMembers)명")
                        .font(.system(size: 13))
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                }
                
                Text(meeting.name)
                    .font(.system(size: 19))
                    .fontWeight(.bold)
                
                HStack {
                    Text("위치가 들어감")
                    Spacer()
                    Text("몇km떨어짐?")
                }
                .font(.system(size: 13))
                .opacity(0.8)
            }
            .padding()
            .foregroundColor(.white)
        }
        .frame(width: 300, height: 200)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isFocusing ? .yellow : Color.clear, lineWidth: 3)
        )
        .animation(.default, value: isFocusing)
    }
}

#Preview {
    MainMapView()
}
