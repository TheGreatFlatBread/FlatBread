//
//  ContentView.swift
//  FlatBread
//
//  Created by andev on 11/4/25.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        // tabItem modifier는 deprecated되었으나,
        // 그 대체제인 Tab은 iOS 18.0 이상부터 사용 가능하므로
        // tabItem modifier를 사용하였음.
        TabView {
            Color(.green)
                .ignoresSafeArea()
                .tabItem {
                    Label("홈", systemImage: "house")
                }
            
            Color(.blue)
                .ignoresSafeArea()
                .tabItem {
                    Label("숏폼", systemImage: "play.rectangle")
                }
            
            MainMapView()
                .tabItem {
                    Label("지도", systemImage: "map")
                }
            
            Color(.yellow)
                .ignoresSafeArea()
                .tabItem {
                    Label("지도", systemImage: "checkmark.rectangle.stack")
                }
            
            Color(.orange)
                .ignoresSafeArea()
                .tabItem {
                    Label("지도", systemImage: "person")
                }
        }
        .tint(.black)
    }
}

#Preview {
    ContentView()
}
