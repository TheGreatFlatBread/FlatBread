//
//  CommentRouterTests.swift
//  FlatBreadTests
//
//  Created by hwan on 11/9/25.
//

import Foundation
import Alamofire
import Testing
@testable import FlatBread

@Suite("CommentRouter endpoint Test")
struct CommentRouterTests {
    
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
    
    @Test("댓글 목록 조회")
    func test_get_commentList() async {
        let sut = makeNetworkService()
        MockURLProtocol.setMock(.commentList)
        
        let result = try? await sut.request(
            CommentRouter.getCommentList(postID: ""),
            responseType: CommentListResponseDTO.self,
            interceptorType: .networkWithToken
        )
        
        #expect(result != nil, "댓글 목록 조회 값은 nil이 아니어야함")
    }
}
