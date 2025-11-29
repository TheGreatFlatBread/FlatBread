//
//  MockURLProtocol.swift
//  FlatBreadTests
//
//  Created by hwan on 11/7/25.
//

import Foundation
import Alamofire
@testable import FlatBread

class MockURLProtocol: URLProtocol {

    enum MockResponse {
        case success(statusCode: Int, dtoType: MockDTOType)
        case httpError(statusCode: Int, dtoType: MockDTOType?)
        case networkError(Error)
        case custom(data: Data?, response: HTTPURLResponse?, error: Error?)
    }

    private static var mockResponse: MockResponse?
    private static var requestCount: Int = 0
    private static var mockDelay: TimeInterval = 0

    // 동적 request handler (테스트별로 커스텀 로직 가능)
    static var requestHandler: ((URLRequest) -> (HTTPURLResponse, Data))?

    static func setMock(_ response: MockResponse) {
        mockResponse = response
    }

    static var totalRequestCount: Int {
        return requestCount
    }

    static var delay: TimeInterval {
        get { mockDelay }
        set { mockDelay = newValue }
    }

    class func reset() {
        mockResponse = nil
        requestCount = 0
        mockDelay = 0
        requestHandler = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        Self.requestCount += 1

        if Self.mockDelay > 0 {
            Thread.sleep(forTimeInterval: Self.mockDelay)
        }

        // requestHandler가 있으면 우선 사용 (동적 응답)
        if let handler = Self.requestHandler {
            let (response, data) = handler(self.request)

            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        // 기존 mockResponse 사용
        guard let mockResponse = Self.mockResponse else {
            fatalError("❌ No mock response or requestHandler")
        }

        handleMockResponse(mockResponse, url: url)
    }

    override func stopLoading() {}

    private func handleMockResponse(_ mockResponse: MockResponse, url: URL) {
        switch mockResponse {
        case .success(let statusCode, let dtoType):
            handleSuccess(url: url, statusCode: statusCode, dtoType: dtoType)

        case .httpError(let statusCode, let dtoType):
            handleHTTPError(url: url, statusCode: statusCode, dtoType: dtoType)

        case .networkError(let error):
            handleNetworkError(error)

        case .custom(let data, let response, let error):
            handleCustom(data: data, response: response, error: error)
        }
    }

    private func handleSuccess(url: URL, statusCode: Int, dtoType: MockDTOType) {
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!

        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)

        if let data = loadMockData(for: dtoType) {
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    private func handleHTTPError(url: URL, statusCode: Int, dtoType: MockDTOType?) {
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!

        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)

        if let dtoType = dtoType, let data = loadMockData(for: dtoType) {
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    private func handleNetworkError(_ error: Error) {
        client?.urlProtocol(self, didFailWithError: error)
    }

    private func handleCustom(data: Data?, response: HTTPURLResponse?, error: Error?) {
        if let error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        if let response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        if let data {
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    private func loadMockData(for dtoType: MockDTOType) -> Data? {
        let fileName = dtoType.fileName
        guard !fileName.isEmpty else { return Data() }

        guard let fileURL = Bundle(for: MockURLProtocol.self).url(
            forResource: fileName,
            withExtension: "json"
        ) else {
            print("❌ Mock JSON not found: \(fileName).json")
            return Data()
        }
        return try? Data(contentsOf: fileURL)
    }
}

// MARK: - Mock DTO Types

extension MockURLProtocol {
    enum MockDTOType {
        case userLogin
        case userJoin
        case emailValidation
        case userProfile
        case userSearch

        case postList
        case postDetail
        case postUpload
        case postLike

        case commentList
        case commentWrite

        case follow
        case like
        case refresh

        case empty

        var fileName: String {
            switch self {
            case .userLogin: return "users_login"
            case .userJoin: return "users_join"
            case .emailValidation: return "validation_email"
            case .userProfile: return "me_profile"
            case .userSearch: return "users_search"

            case .postList: return "posts"
            case .postDetail: return "post_postID"
            case .postUpload: return "posts_files"
            case .postLike: return "posts"

            case .commentList: return "comments"
            case .commentWrite: return "comment"

            case .follow: return "follow"
            case .like: return "like"
            case .refresh: return "refresh"
            case .empty: return ""
            }
        }
    }
}

// MARK: - Static Helper Methods

extension MockURLProtocol {
    static func setMock(_ dtoType: MockDTOType, statusCode: Int = 200) {
        setMock(.success(statusCode: statusCode, dtoType: dtoType))
    }

    static func setMockHTTPError(_ dtoType: MockDTOType? = nil, statusCode: Int) {
        setMock(.httpError(statusCode: statusCode, dtoType: dtoType))
    }

    static func setMockNetworkError(_ error: Error) {
        setMock(.networkError(error))
    }
}

// MARK: - Token Refresh Mock Helpers

extension MockURLProtocol {
    static func setMockSuccess(accessToken: String, refreshToken: String, statusCode: Int = 200) {
        let response = RefreshTokenResponseDTO(accessToken: accessToken, refreshToken: refreshToken)
        let data = try? JSONEncoder().encode(response)
        let httpResponse = HTTPURLResponse(
            url: URL(string: "https://api.hwan.com/refresh")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
        setMock(.custom(data: data, response: httpResponse, error: nil))
    }

    static func setMockFailure(statusCode: Int = 401) {
        let httpResponse = HTTPURLResponse(
            url: URL(string: "https://api.hwan.com/refresh")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
        let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: statusCode))
        setMock(.custom(data: nil, response: httpResponse, error: error))
    }
}
