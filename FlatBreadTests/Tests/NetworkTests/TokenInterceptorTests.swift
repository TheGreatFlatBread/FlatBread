//
//  TokenInterceptorTests.swift
//  FlatBreadTests
//
//  실제 네트워크 요청 + Interceptor 전체 플로우 테스트
//

import Foundation
import Testing
import Alamofire
@testable import FlatBread

final class TokenInterceptorMockProtocol: MockURLProtocol {
    static var refreshCallCount = 0
    static var apiCallCount = 0

    override class func reset() {
        super.reset()
        refreshCallCount = 0
        apiCallCount = 0
        requestHandler = nil
    }
}

@Suite("TokenInterceptor - 실제 네트워크 요청 플로우")
struct TokenInterceptorIntegrationTests {

    @Test("10개 동시 요청 -> 1개 refresh 진입, 6개 waiting, 3개 뒤늦게 retry -> refresh 스킵 확인")
    func test_10ConcurrentRequests_interceptorFlow() async throws {
        // Given: Session with Interceptor
        let storage = MockTokenStorage(
            accessToken: "expired-token-will-get-401",
            refreshToken: "valid-refresh-token"
        )

        let configuration = URLSessionConfiguration.af.default
        configuration.protocolClasses = [TokenInterceptorMockProtocol.self]

        // 1. Session 먼저 생성
        let session = Session(configuration: configuration)

        // 2. Coordinator 생성 (session 필요)
        let coordinator = TokenRefreshCoordinator(tokenStorage: storage, session: session)

        // 3. Interceptor 생성 (coordinator 필요)
        let interceptor = TokenInterceptor(coordinator: coordinator, maxCount: 3)


        TokenInterceptorMockProtocol.reset()

        // Mock 설정: 첫 호출은 401, refresh 후 재시도는 200
        TokenInterceptorMockProtocol.requestHandler = { request in
            let authHeader = request.value(forHTTPHeaderField: "Authorization") ?? ""

            // refresh API (URL 경로로 판단)
            if request.url?.path.contains("refresh") == true ||
               request.url?.absoluteString.contains("auth") == true {
                TokenInterceptorMockProtocol.refreshCallCount += 1
                print("   [Mock] refresh API (#\(TokenInterceptorMockProtocol.refreshCallCount))")

                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!

                let data = """
                {
                    "accessToken": "new-fresh-token-123",
                    "refreshToken": "new-refresh-token-456"
                }
                """.data(using: .utf8)!

                return (response, data)
            }

            // 일반 API
            TokenInterceptorMockProtocol.apiCallCount += 1

            // 만료된 토큰이면 401
            if authHeader == "expired-token-will-get-401" {
                print("   [Mock] -> 401 (만료 토큰)")
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 401,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                // 빈 JSON으로 변경 (serialization 에러 방지)
                return (response, "{}".data(using: .utf8)!)
            }

            // 새 토큰이면 200
            print("   [Mock] -> 200 (성공)")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!

            let data = """
            {
                "success": true,
                "message": "OK"
            }
            """.data(using: .utf8)!

            return (response, data)
        }

        // When: 10개 요청 동시 발송
        var results: [Result<String, Error>] = []

        await withTaskGroup(of: (Int, Result<String, Error>).self) { group in
            for i in 0..<10 {
                group.addTask {
                    let startTime = Date()
                    do {
                        let request = session.request("https://api.example.com/test/\(i)", interceptor: interceptor)
                        let response = try await request
                            .validate(statusCode: 200..<300)
                            .serializingData()
                            .value

                        let elapsed = Date().timeIntervalSince(startTime)
                        print(" response: \(response)")
                        print("  [\(i)] 성공 (\(String(format: "%.3f", elapsed))초)")

                        return (i, .success("success"))
                    } catch {
                        let elapsed = Date().timeIntervalSince(startTime)
                        print("  [\(i)] 실패 (\(String(format: "%.3f", elapsed))초): \(error)")

                        return (i, .failure(error))
                    }
                }
            }

            for await (_, result) in group {
                results.append(result)
            }
        }

        // Then
        print("\n테스트 결과:")
        print("   총 API 호출 횟수: \(TokenInterceptorMockProtocol.apiCallCount)")
        print("   refresh API 호출 횟수: \(TokenInterceptorMockProtocol.refreshCallCount)")
        print("   성공한 요청: \(results.filter { if case .success = $0 { return true }; return false }.count)")
        print("   실패한 요청: \(results.filter { if case .failure = $0 { return true }; return false }.count)")

        // 검증
        #expect(TokenInterceptorMockProtocol.refreshCallCount == 1, "refresh는 정확히 1번만 호출되어야 함")
        #expect(results.filter { if case .success = $0 { return true }; return false }.count == 10, "모든 요청이 성공해야 함")

        // API 호출 횟수: 첫 시도 10번 (모두 401) + 재시도 10번 (성공) = 20번
        #expect(TokenInterceptorMockProtocol.apiCallCount == 20, "첫 시도 10번 + 재시도 10번 = 20번")
    }

    @Test("refresh 완료 후 도착한 401은 refresh skip")
    func test_lateArrivingRequest_shouldSkipRefresh() async throws {
        let storage = MockTokenStorage(accessToken: "old", refreshToken: "valid")
        let configuration = URLSessionConfiguration.af.default
        configuration.protocolClasses = [TokenInterceptorMockProtocol.self]

        let session = Session(configuration: configuration)
        let coordinator = TokenRefreshCoordinator(tokenStorage: storage, session: session)
        let interceptor = TokenInterceptor(coordinator: coordinator)

        TokenInterceptorMockProtocol.reset()

        TokenInterceptorMockProtocol.requestHandler = { request in
            let token = request.value(forHTTPHeaderField: "Authorization") ?? ""
            let url = request.url?.absoluteString ?? ""

            // refresh API
            if url.contains("auth") {
                print("[Mock] refresh 시작")
                TokenInterceptorMockProtocol.refreshCallCount += 1
                print("[Mock] refresh 완료")

                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, "{\"accessToken\": \"new\", \"refreshToken\": \"new\"}".data(using: .utf8)!)
            }

            // 일반 API
            TokenInterceptorMockProtocol.apiCallCount += 1

            // old 토큰이면 401
            if token == "old" {
                print("[Mock] old 토큰 -> 401 반환")
                let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
                return (response, "{}".data(using: .utf8)!)
            }

            // new 토큰이면 200
            print("[Mock] new 토큰 -> 200 반환")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "{}".data(using: .utf8)!)
        }

        // When: 처음 2개 발송 → refresh 완료 → 3번째 발송
        var success = 0

        // 1단계: 처음 2개 발송 (refresh 완료까지)
        await withTaskGroup(of: Bool.self) { group in
            for i in 0..<2 {
                group.addTask {
                    let result = try? await session.request("https://api.example.com/\(i)", interceptor: interceptor)
                        .validate(statusCode: 200..<300)
                        .serializingData().value
                    return result != nil
                }
            }

            for await result in group {
                if result { success += 1 }
            }
        }

        // 2단계: refresh 완료 후 3번째 발송 (old 토큰 직접 설정)
        var urlRequest = URLRequest(url: URL(string: "https://api.example.com/late")!)
        urlRequest.headers.add(HTTPHeader(name: "Authorization", value: "old"))

        let result = try? await session.request(urlRequest, interceptor: interceptor)
            .validate(statusCode: 200..<300)
            .serializingData().value

        if result != nil { success += 1 }

        // Then
        #expect(TokenInterceptorMockProtocol.refreshCallCount == 1)
        #expect(success == 3)
        #expect(TokenInterceptorMockProtocol.apiCallCount == 6)
    }
}
