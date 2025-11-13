//
//  ContentView.swift
//  FlatBread
//
//  Created by andev on 11/4/25.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var viewModel = LoginViewModel(tokenStorage: DefaultTokenStorage())
    
    var body: some View {
        if viewModel.isLoginSucceed {
            Color.yellow
        } else {
            LoginView(
                isLoginSucceed: $viewModel.isLoginSucceed,
                viewModel: viewModel
            )
        }
    }
}

#Preview {
    ContentView()
}
