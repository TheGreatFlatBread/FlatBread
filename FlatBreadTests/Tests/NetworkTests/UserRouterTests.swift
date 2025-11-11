//
//  UserRouterTests.swift
//  FlatBreadTests
//
//  Created by hwan on 11/9/25.
//
import Foundation
import Testing
import Alamofire
@testable import FlatBread


@Suite("UserRouter endpoint Test")
struct UserRouterTests {
    
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
    
    @Test("회원가입 성공")
    func test_signUpSuccess() async {
        let sut = makeNetworkService()
        MockURLProtocol.setMock(.userJoin)
        
        let result = try? await sut.request(
            UserRouter.signUp(request: UserSignUpRequestDTO(email: "hwan@gmail.com", password: "134", nick: "hwan")),
            responseType: UserSignUpResponseDTO.self,
            interceptorType: .networkWithToken
        )
        #expect(result != nil, "회원 가입 성공")
    }

    @Test("로그인 성공")
    func test_success() async {
        // Given
        let sut = makeNetworkService()
        MockURLProtocol.setMock(.userLogin)

        // When
        let result = try? await sut.request(
            UserRouter.login(email: "test@gmailc.com", password: "11123@123"),
            responseType: UserLoginResponseDTO.self,
            interceptorType: .networkWithToken
        )

        // Then
        #expect(result!.accessToken!.isEmpty == false)
    }

    @Test("로그인 실패 - 401 Unauthorized(invalidToken)")
    func test_unauthorized() async {
        // Given
        let sut = makeNetworkService()
        MockURLProtocol.setMockHTTPError(statusCode: 401)

        // Then
        await #expect(throws: NetworkError.apiError(.invalidAccessToken), "401 에러 발생") {
            try await sut.request(
                UserRouter.login(email: "test@gmailc.com", password: "11123@123"),
                responseType: UserLoginResponseDTO.self,
                interceptorType: .networkWithToken
            )
        }
    }

    @Test("로그인 실패 - 타임아웃")
    func test_timeout() async {
        // Given
        let sut = makeNetworkService()
        MockURLProtocol.setMockNetworkError(NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut))

        // Then
        await #expect(throws: NetworkError.timeout, "timeout 에러 발생") {
            try await sut.request(
                UserRouter.login(email: "test@gmailc.com", password: "11123@123"),
                responseType: UserLoginResponseDTO.self,
                interceptorType: .networkWithToken
            )
        }
    }

    @Test("로그인 실패 - 인터넷 연결 없음")
    func test_internetConnection() async {
        // Given
        let sut = makeNetworkService()
        MockURLProtocol.setMockNetworkError(NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet))

        // Then
        await #expect(throws: NetworkError.noInternetConnection, "인터넷 연결 에러 발생") {
            try await sut.request(
                UserRouter.login(email: "test@gmailc.com", password: "11123@123"),
                responseType: UserLoginResponseDTO.self,
                interceptorType: .networkWithToken
            )
        }
    }

    @Test("로그인 실패 - 호스트를 찾을수 없음")
    func test_cannotFindHost() async {
        // Given
        let sut = makeNetworkService()
        MockURLProtocol.setMockNetworkError(URLError(URLError.Code.cannotFindHost))

        // Then
        await #expect(throws: NetworkError.networkFailure, "호스트 찾기 실패 에러 발생") {
            try await sut.request(
                UserRouter.login(email: "test@gmail.com", password: "11123@123"),
                responseType: UserLoginResponseDTO.self,
                interceptorType: .networkWithToken
            )
        }
    }
    
    @Test("이메일 중복 체크")
    func test_emailValidation() async {
        let sut = makeNetworkService()
        MockURLProtocol.setMock(.emailValidation)
        
        let result = try? await sut.request(
            UserRouter.validation(email: "test@gmail.com"),
            responseType: EmailValidationResponseDTO.self,
            interceptorType: .networkWithToken
        )
        
        #expect(result != nil)
    }
    
    @Test("유저 검색")
    func test_serchUser() async {
        let sut = makeNetworkService()
        MockURLProtocol.setMock(.userSearch)
        
        let result = try? await sut.request(
            UserRouter.searchUser(nick: "hwan"),
            responseType: SearchUserResponseDTO.self,
            interceptorType: .networkWithToken
        )
        #expect(result != nil)
    }
    
    @Test("내 프로필 조회")
    func test_getMeProfile() async {
        let sut = makeNetworkService()
        MockURLProtocol.setMock(.userProfile)
        
        let result = try? await sut.request(
            UserRouter.getMeProfile,
            responseType: UserProfileResponseDTO.self,
            interceptorType: .networkWithToken
        )
        #expect(result != nil)
    }
}
