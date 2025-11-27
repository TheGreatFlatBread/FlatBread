//
//  FlatBreadApp.swift
//  FlatBread
//
//  Created by andev on 11/4/25.
//

import SwiftUI

@main
struct FlatBreadApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.imageService, ImageServiceKey.defaultValue)
        }
    }
}
