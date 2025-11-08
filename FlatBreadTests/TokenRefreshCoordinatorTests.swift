//
//  TokenRefreshCoordinatorTests.swift
//  FlatBreadTests
//
//  Created by hwan on 11/7/25.
//

import Testing
import Alamofire
@testable import FlatBread

@Suite("TokenRefreshCoordinator - 동시성 테스트", .serialized)
struct TokenRefreshCoordinatorTests {
    var factory: MockSessionFactory
    var coordinator: TokenRefreshCoordinator
    var tokenStorage: MockTokenStorage
    
    init() {
        self.factory = MockSessionFactory(accessToken: "accessToken", refreshToken: "refreshToken")
        self.coordinator = self.factory.tokenCoordinator
        self.tokenStorage = self.factory.tokenStorage
        MockURLProtocol.reset()
    }

    @Test("동시에 10개 요청해도 refresh API는 1번만 호출됨")
    func concurrentRefreshCallsAPIOnlyOnce() async throws {
        // Given
        MockURLProtocol.setMockSuccess(
            accessToken: "new-access-token",
            refreshToken: "new-refresh-token"
        )

        // When
        await withTaskGroup(of: Result<String, Error>.self) { group in
            for _ in 0..<10 {
                group.addTask { [coordinator] in
                    do {
                        let token = try await coordinator.refreshToken()
                        return .success(token)
                    } catch {
                        return .failure(error)
                    }
                }
            }
        }

        // Then
        #expect(MockURLProtocol.requestCallCount == 1, "API는 정확히 1번만 호출되어야 함")
    }

    @Test("동시 요청 시 모든 요청이 동일한 새 토큰을 받음")
    func concurrentRefreshReturnsConsistentToken() async throws {
        // Given
        let expectedToken = "new-consistent-token-123"
        MockURLProtocol.setMockSuccess(
            accessToken: expectedToken,
            refreshToken: "new-refresh-456"
        )

        // When
        var tokens: [String] = []
        await withTaskGroup(of: String?.self) { group in
            for _ in 0..<10 {
                group.addTask { [coordinator] in
                    do {
                        let token = try await coordinator.refreshToken()
                        return token
                    } catch {
                        return nil
                    }
                }
            }

            for await token in group {
                if let token = token {
                    tokens.append(token)
                }
            }
        }

        // Then
        #expect(tokens.count == 10, "모든 요청이 성공해야 함")
        #expect(Set(tokens).count == 1, "모든 토큰이 동일해야 함")
        #expect(tokens.first == expectedToken, "올바른 토큰을 받아야 함")
    }

    @Test("refresh 실패 시 모든 대기 중인 요청도 동일하게 실패")
    func concurrentRefreshPropagatesErrorToAll() async throws {
        // Given
        MockURLProtocol.setMockFailure(statusCode: 401)

        // When
        var successCount = 0
        var errorCount = 0

        await withTaskGroup(of: Result<String, Error>.self) { group in
            for _ in 0..<10 {
                group.addTask { [coordinator] in
                    do {
                        let token = try await coordinator.refreshToken()
                        return .success(token)
                    } catch {
                        return .failure(error)
                    }
                }
            }

            for await result in group {
                switch result {
                case .success:
                    successCount += 1
                case .failure:
                    errorCount += 1
                }
            }
        }

        // Then
        #expect(successCount == 0, "성공한 요청이 없어야 함")
        #expect(errorCount == 10, "모든 요청이 실패해야 함")
        #expect(MockURLProtocol.requestCallCount == 1, "실패해도 API는 1번만 호출")
    }

    @Test("첫 번째 refresh 완료 후 두 번째 refresh는 새로 호출됨")
    func sequentialRefreshCallsAPITwice() async throws {
        // Given
        MockURLProtocol.setMockSuccess(
            accessToken: "token-1",
            refreshToken: "refresh-1"
        )

        // When: 첫 번째 refresh
        let token1 = try await coordinator.refreshToken()
        let firstCallCount = MockURLProtocol.requestCallCount

        
        MockURLProtocol.setMockSuccess(
            accessToken: "token-2",
            refreshToken: "refresh-2"
        )
        let token2 = try await coordinator.refreshToken()
        let secondCallCount = MockURLProtocol.requestCallCount

        // Then
        #expect(firstCallCount == 1, "첫 번째 호출 후 count는 1")
        #expect(secondCallCount == 2, "두 번째 호출 후 count는 2")
        #expect(token1 == "token-1")
        #expect(token2 == "token-2")
    }

    @Test("첫 요청 완료 전 동시 요청은 대기, 완료 후 요청은 새로 호출")
    func mixedConcurrentAndSequentialRequests() async throws {
        // Given
        MockURLProtocol.delay = 0.1
        MockURLProtocol.setMockSuccess(
            accessToken: "token-first-batch",
            refreshToken: "refresh-first-batch"
        )

        // When
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask { [coordinator] in
                    _ = try? await coordinator.refreshToken()
                }
            }
        }

        let firstBatchCount = MockURLProtocol.requestCallCount
        try? await Task.sleep(for: .milliseconds(200))
        MockURLProtocol.setMockSuccess(
            accessToken: "token-second-batch",
            refreshToken: "refresh-second-batch"
        )
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask { [coordinator] in
                    _ = try? await coordinator.refreshToken()
                }
            }
        }
        let secondBatchCount = MockURLProtocol.requestCallCount

        // Then
        #expect(firstBatchCount == 1, "첫 번째 배치는 1번만 호출")
        #expect(secondBatchCount == 2, "두 번째 배치는 추가로 1번 호출")
    }

    @Test("refresh 성공 시 새 토큰이 storage에 저장됨")
    func successfulRefreshSavesTokenToStorage() async throws {
        // Given
        let newAccessToken = "saved-access-token"
        let newRefreshToken = "saved-refresh-token"

        MockURLProtocol.setMockSuccess(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken
        )

        // When
        _ = try await coordinator.refreshToken()

        // Then
        let savedAccess = await tokenStorage.getAccessToken()
        let savedRefresh = await tokenStorage.getRefreshToken()
        let saveCallCount = await tokenStorage.saveTokenCallCount

        #expect(savedAccess == newAccessToken, "새 access token이 저장되어야 함")
        #expect(savedRefresh == newRefreshToken, "새 refresh token이 저장되어야 함")
        #expect(saveCallCount == 1, "saveToken이 1번 호출되어야 함")
    }
}
