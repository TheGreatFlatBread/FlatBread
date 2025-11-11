//
//  PostRouterTests.swift
//  FlatBreadTests
//
//  Created by hwan on 11/9/25.
//

import Foundation
import Alamofire
import Testing
@testable import FlatBread


@Suite("PostRouter endpoint Test")
struct PostRouterTests {
    
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
    
    @Test("게시글 조회")
    func test_get_postList() async {
        let sut = makeNetworkService()
        MockURLProtocol.setMock(.postList)
        
        let result = try? await sut.request(
            PostRouter.getPostList(next: "abc", limit: "1", category: ["abc"]),
            responseType: PostListResponseDTO.self,
            interceptorType: .networkWithToken
        )
        
        #expect(result != nil, "포스트 조회 값은 nil이 아니어야함")
    }
    
    @Test("Like 게시글 조회")
    func test_get_like_postList() async {
        let sut = makeNetworkService()
        MockURLProtocol.setMock(.postLike)
        
        let result = try? await sut.request(
            PostRouter.getPostList(next: "", limit: "", category: []),
            responseType: PostListResponseDTO.self,
            interceptorType: .networkWithToken
        )
        
        #expect(result != nil, "Like 포스트 조회 값은 nil이 아니어야함")
    }
    
    @Test("Like 디코딩 테스트")
    func test_like_decoding() async {
        let sut = makeNetworkService()
        MockURLProtocol.setMock(.like)
        
        let result = try? await sut.request(
            PostRouter.togglePostLikeV1(postID: "", like_status: false),
            responseType: LikeResponseDTO.self,
            interceptorType: .networkWithToken
        )
        
        #expect(result != nil, "Like response decoding")
    }
    
}
