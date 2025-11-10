//
//  MockSession.swift
//  FlatBreadTests
//
//  Created by hwan on 11/7/25.
//

import Foundation
import Alamofire
@testable import FlatBread

final class MockSessionFactory {

    var tokenCoordinator: TokenRefreshCoordinator
    var tokenStorage: MockTokenStorage
    var session: Session

    init(accessToken: String, refreshToken: String, protocolClass: URLProtocol.Type) {
        let mainSession = Self.createMockSession(protocolClass: protocolClass)
        self.tokenStorage = MockTokenStorage(accessToken: accessToken, refreshToken: refreshToken)
        self.tokenCoordinator = TokenRefreshCoordinator(
            tokenStorage: tokenStorage,
            session: mainSession
        )
        self.session = mainSession
    }

    static func createMockSession(protocolClass: URLProtocol.Type) -> Session {
        let configuration = URLSessionConfiguration.af.ephemeral
        configuration.protocolClasses = [protocolClass]
        return Session(configuration: configuration)
    }

    func makeNetworkService() -> AsyncNetworkService {
        DefaultNetworkService(
            session: session,
            tokenInterceptor: TokenInterceptor(coordinator: tokenCoordinator),
            networkRetrier: NetworkRetryRetrier()
        )
    }
}
