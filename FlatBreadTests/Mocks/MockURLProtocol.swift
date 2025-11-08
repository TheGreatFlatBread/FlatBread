//
//  MockURLProtocol.swift
//  FlatBreadTests
//
//  Created by hwan on 11/7/25.
//

import Foundation
import Alamofire
@testable import FlatBread

final class MockURLProtocol: URLProtocol {

    static var mockResponse: (data: Data?, response: HTTPURLResponse?, error: Error?)?
    static var requestCallCount = 0
    static var delay: TimeInterval = 0

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        Self.requestCallCount += 1

        if Self.delay > 0 {
            Thread.sleep(forTimeInterval: Self.delay)
        }

        if let error = Self.mockResponse?.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        if let response = Self.mockResponse?.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        if let data = Self.mockResponse?.data {
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        
    }

    static func reset() {
        mockResponse = nil
        requestCallCount = 0
        delay = 0
    }
}


// MARK: Token Simualation
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
        mockResponse = (data, httpResponse, nil)
    }

    static func setMockFailure(statusCode: Int = 401) {
        let httpResponse = HTTPURLResponse(
            url: URL(string: "https://api.hwan.com/refresh")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
        let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: statusCode))
        mockResponse = (nil, httpResponse, error)
    }
}
