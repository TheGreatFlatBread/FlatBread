//
//  ContentView.swift
//  FlatBread
//
//  Created by andev on 11/4/25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    
    init() {
        let defaultAppearance = UITabBarAppearance()
        defaultAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = defaultAppearance
        UITabBar.appearance().scrollEdgeAppearance = defaultAppearance
    }
    
    var body: some View {
        TabView {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
            }
            .padding()
            .tabItem {
                Image(systemName: "house")
                Text("홈")
            }
            
            MainMapView()
                .tabItem {
                    Image(systemName: "map")
                    Text("지도")
                }
        }
    }
}

#Preview {
    ContentView()
}
