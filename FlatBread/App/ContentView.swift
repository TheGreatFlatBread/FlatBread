//
//  ContentView.swift
//  FlatBread
//
//  Created by andev on 11/4/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = LoginViewModel(tokenStorage: DefaultTokenStorage())
    @State private var showOnboarding = false
    
    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    private func checkOnboardingNeeded() async {
        do {
            let response = try await NetworkServiceFactory.shared
                .makeNetworkService()
                .request(UserRouter.getMeProfile, responseType: UserProfileResponseDTO.self, interceptorType: .networkWithToken)
            showOnboarding = (response.info1 == nil)
        } catch {
            showOnboarding = true
        }
    }
    
    var body: some View {
        Group {
            if viewModel.isCheckingLoginStatus {
                ProgressView()
            } else if viewModel.isLoginSucceed {
                // tabItem modifier는 deprecated되었으나,
                // 그 대체제인 Tab은 iOS 18.0 이상부터 사용 가능하므로
                // tabItem modifier를 사용하였음.
                TabView {
                    HomeContainerView()
                        .tabItem {
                            Label("홈", systemImage: "house")
                        }
                    
                    ShortVideoFeedView()
                        .tabItem {
                            Label("숏폼", systemImage: "play.rectangle")
                        }
                    
                    MainMapView()
                        .tabItem {
                            Label("지도", systemImage: "map")
                        }
                    
                    MyMoimView()
                        .ignoresSafeArea()
                        .tabItem {
                            Label("내 모임", systemImage: "message")
                        }
                    
                    ProfileView()
                        .ignoresSafeArea()
                        .tabItem {
                            Label("내 프로필", systemImage: "person")
                        }
                }
                .tint(.black)
                .task {
                    await checkOnboardingNeeded()
                }
                .fullScreenCover(isPresented: $showOnboarding, onDismiss: {
                    Task {
                        await checkOnboardingNeeded()
                    }
                }) {
                    OnBoardingView()
                }
            } else {
                LoginView(
                    isLoginSucceed: $viewModel.isLoginSucceed,
                    viewModel: viewModel
                )
            }
        }
        .task {
            await viewModel.checkLoginStatus()
        }
    }
}

#Preview {
    ContentView()
}
