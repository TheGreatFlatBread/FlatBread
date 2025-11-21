//
//  NetworkServiceFactory.swift
//  FlatBread
//
//  Created by hwan on 11/7/25.
//

import Foundation
import Alamofire

final class NetworkServiceFactory {
    static let shared = NetworkServiceFactory()
    private let tokenStorage: TokenStorage
    private let tokenCoordinator: TokenRefreshCoordinator
    private let tokenInterceptor: TokenInterceptor
    private let session: Session
    private lazy var networkService = DefaultNetworkService(
        session: session,
        tokenInterceptor: tokenInterceptor,
        networkRetrier: NetworkRetryRetrier()
    )
    
    private init(tokenStorage: TokenStorage = DefaultTokenStorage(), eventMonitor: APIEventLogger? = nil) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 60
        
        let mainSession = if let eventMonitor {
            Session(
                configuration: configuration,
                eventMonitors: [eventMonitor]
            )
        } else {
            Session(configuration: configuration)
        }
        
        self.tokenStorage = tokenStorage
        self.tokenCoordinator = TokenRefreshCoordinator(
            tokenStorage: tokenStorage,
            session: mainSession
        )
        self.tokenInterceptor = TokenInterceptor(coordinator: tokenCoordinator)
        self.session = mainSession
    }

    func makeNetworkService() -> AsyncNetworkService {
        networkService
    }
    
    func makeReactiveNetworkService() -> ReactiveNetworkService {
        networkService
    }
    
    func getTokenCoordinator() -> TokenRefreshCoordinator {
        tokenCoordinator
    }

    func getTokenInterceptor() -> TokenInterceptor {
        tokenInterceptor
    }
}
