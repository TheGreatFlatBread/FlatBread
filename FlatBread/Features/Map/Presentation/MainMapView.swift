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
    
    @StateObject private var viewModel: MainMapViewModel
    @FocusState private var searchBarFocused: Bool
    @State private var isSearchActive: Bool = false
//    @Namespace private var animation
    
    init(initialPosition: NMGLatLng = .init(lat: 37.517677, lng: 126.886442)) {
        let viewModel = MainMapViewModel(coordinate: initialPosition)
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            ZStack {
                NaverMapView(
                    coordinate: $viewModel.coordinate,
                    markers: $viewModel.markers,
                    focusingPlaceID: $viewModel.focusingPlaceID
                )
                .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.nearbyMoims) { moim in
                                MoimCardView(
                                    moimModel: moim,
                                    isFocusing: viewModel.focusingPlaceID == moim.id
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
                    .onChange(of: viewModel.focusingPlaceID) { _, newValue in
                        guard let currentPlaceID  = newValue else { return }
                        withAnimation {
                            scrollViewProxy.scrollTo(currentPlaceID, anchor: .center)
                        }
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                
                ZStack {
                    if isSearchActive {
                        Color(UIColor.systemGray6)
                            .ignoresSafeArea()
                    }
                    
                    VStack {
                        HStack(spacing: 12) {
                            MainMapSearchBar(searchText: $viewModel.searchText)
                                .focused($searchBarFocused)
                            
                            if isSearchActive {
                                Button {
                                    withAnimation {
                                        searchBarFocused = false
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 17))
                                        .padding(12)
                                        .background(Color.white)
                                        .foregroundStyle(.gray)
                                        .cornerRadius(.infinity)
                                        .shadow(radius: 8)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach($viewModel.categories, id: \.name) { category in
                                    MainMapCategoryButton(category: category)
                                }
                            }
                            .padding(.vertical, 1.5)
                            .padding(.horizontal)
                        }
                        .scrollIndicators(.hidden)
                        
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
                }
            }
        }
        .onChange(of: searchBarFocused) { oldValue, newValue in
            withAnimation {
                isSearchActive = newValue
            }
        }
        .task {
            await viewModel.requestNearbyMoimList()
        }
    }
    
    func handleCardClick(moimID: String) {
        if let selectedPosition = viewModel.nearbyMoims.filter({ $0.id == moimID }).first {
            viewModel.focusingPlaceID = moimID
            viewModel.coordinate = selectedPosition.location
        }
        viewModel.focusingPlaceID = moimID
    }
}

#Preview {
    MainMapView()
}
