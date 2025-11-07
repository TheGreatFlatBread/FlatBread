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
    
    @State var coordinate: NMGLatLng = .init(lat: 37.517677, lng: 126.886442)
    @State private var activeMeetingId: Int? = nil
    @State private var searchText: String = ""
    @State private var meetings: [MoimInMainMap] = []
    @State private var markers: [NMFMarker] = []
    
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            ZStack {
                NaverMapView(
                    coordinate: $coordinate,
                    markers: $markers
                )
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
                            ForEach(meetings) { meeting in
                                MeetingCardView(
                                    meeting: meeting,
                                    isActive: activeMeetingId == meeting.id
                                )
                                .onTapGesture {
                                    handleCardClick(meetingId: meeting.id)
                                }
                                .id(meeting.id)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                    .background(Color.clear)
                }
            }
        }
        .onAppear {
            meetings = MoimInMainMap.makeSample()
            markers = meetings.map({
                return NMFMarker(position: NMGLatLng(from: $0.location))
            })
        }
    }
    
    func handleMarkerClick(meetingId: Int, proxy: ScrollViewProxy) {
        activeMeetingId = meetingId
        if let selectedPosition = meetings.filter({ $0.id == meetingId }).first {
            coordinate = NMGLatLng(from: selectedPosition.location)
        }
        
        withAnimation(.smooth) {
            proxy.scrollTo(meetingId, anchor: .center)
        }
    }
    
    func handleCardClick(meetingId: Int) {
        if let selectedPosition = meetings.filter({ $0.id == meetingId }).first {
            coordinate = NMGLatLng(from: selectedPosition.location)
        }
        activeMeetingId = meetingId
    }
}

struct MeetingCardView: View {
    let meeting: MoimInMainMap
    let isActive: Bool
    
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
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Text("\(meeting.currentMembers)/\(meeting.maxMembers)명")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                }
                
                Text(meeting.name)
                    .font(.title3)
                    .fontWeight(.bold)
                
                HStack {
                    Text("위치가 들어감")
                    Spacer()
                    Text("몇km떨어짐?")
                }
                .font(.subheadline)
                .opacity(0.8)
            }
            .padding()
            .foregroundColor(.white)
        }
        .frame(width: 300, height: 200)
        .cornerRadius(16)
        .shadow(radius: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isActive ? Color.blue : Color.clear, lineWidth: 3)
        )
        .animation(.default, value: isActive)
    }
}

#Preview {
    MainMapView()
}
