//
//  ContentView.swift
//  FlatBread
//
//  Created by andev on 11/4/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = LoginViewModel(tokenStorage: DefaultTokenStorage())
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    @StateObject private var deepLinkHandler = DeepLinkHandler()
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
                TabView(selection: Binding(
                    get: { navigationCoordinator.selectedTab.rawValue },
                    set: { navigationCoordinator.selectedTab = TabType(rawValue: $0) ?? .home }
                )) {
                    HomeContainerView()
                        .environmentObject(navigationCoordinator.homeRouter)
                        .tabItem {
                            Label("홈", systemImage: "house")
                        }
                        .tag(0)

                    ShortVideoFeedView()
                        .environmentObject(navigationCoordinator.shortVideoRouter)
                        .tabItem {
                            Label("숏폼", systemImage: "play.rectangle")
                        }
                        .tag(1)

                    MainMapView()
                        .environmentObject(navigationCoordinator.mapRouter)
                        .tabItem {
                            Label("지도", systemImage: "map")
                        }
                        .tag(2)

                    MyMoimView()
                        .environmentObject(navigationCoordinator.myMoimRouter)
                        .ignoresSafeArea()
                        .tabItem {
                            Label("내 모임", systemImage: "message")
                        }
                        .tag(3)

                    ProfileView()
                        .environmentObject(navigationCoordinator.profileRouter)
                        .ignoresSafeArea()
                        .tabItem {
                            Label("내 프로필", systemImage: "person")
                        }
                        .tag(4)
                }
                .tint(.black)
                .onAppear {
                    print("[ContentView] TabView 렌더링 완료")
                    deepLinkHandler.coordinator = navigationCoordinator
                }
                .onOpenURL { url in
                    print("[ContentView] onOpenURL 호출: \(url.absoluteString)")
                    deepLinkHandler.handle(url: url)
                }
                .onReceive(NotificationCenter.default.publisher(for: .handleDeepLink)) { notification in
                    if let url = notification.object as? URL {
                        print("[ContentView] NotificationCenter로 DeepLink 수신: \(url.absoluteString)")
                        deepLinkHandler.handle(url: url)
                    }
                }
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
