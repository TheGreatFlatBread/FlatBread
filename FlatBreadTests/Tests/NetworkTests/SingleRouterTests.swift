//
//  SingleRouterTests.swift
//  FlatBreadTests
//
//  Created by hwan on 11/9/25.
//

import Foundation
import Alamofire
import Testing
@testable import FlatBread

@Suite("SingleRouter endpoint Test")
struct SingleRouterTests {
    
    init() {
        MockURLProtocol.reset()
    }

    func makeNetworkService() -> DefaultNetworkService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = Session(configuration: configuration)
        let mockCoordinator = TokenRefreshCoordinator(tokenStorage: MockTokenStorage(), session: session)
        let tokenInterceptor = TokenInterceptor(coordinator: mockCoordinator)

        return DefaultNetworkService(
            session: session,
            tokenInterceptor: tokenInterceptor,
            networkRetrier: NetworkRetryRetrier(maxRetryCount: 2, retryDelay: 0)
        )
    }
    
    @Test("Follow Router 테스트")
    func test_get_follow() async {
        let sut = makeNetworkService()
        MockURLProtocol.setMock(.like)
        
        let result = try? await sut.request(
            FollowRouter(userID: "", isFollow: false),
            responseType: FollowResponseDTO.self,
            interceptorType: .networkWithToken
        )
        
        #expect(result != nil, "Follow decoding Test")
    }
    
    @Test("Refresh Router 테스트")
    func test_refresh_token() async throws {
        let sut = makeNetworkService()
        MockURLProtocol.setMock(.refresh)
        do {
            let result = try await sut.request(
                RefreshRouter(refreshToken: "", accessToken: ""),
                responseType: RefreshTokenResponseDTO.self,
                interceptorType: .networkWithToken
            )
            #expect(result.accessToken!.isEmpty == false, "Refresh decoding Test")
        } catch {
            throw error
        }
    }
}
