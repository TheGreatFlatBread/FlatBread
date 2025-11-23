//
//  Network+protocol.swift
//  FlatBread
//
//  Created by hwan on 11/8/25.
//

import Foundation
import Combine
import Alamofire

protocol AsyncNetworkService: Sendable {
    func request<T: Decodable & Sendable>(_ router: APIRouter,
                                          responseType: T.Type,
                                          interceptorType: InterceptorType) async throws(NetworkError) -> T
    func upload<T: Decodable & Sendable>(_ router: MultipartAPIRouter,
                                         responseType: T.Type,
                                         interceptorType: InterceptorType,
                                         progress: (@Sendable (Double) -> Void)?) async throws(NetworkError) -> T
    func download(_ router: DownloadAPIRouter,
                  interceptorType: InterceptorType) async throws(NetworkError) -> URL
    func downloadVideo(_ router: any APIRouter,
                       interceptorType: InterceptorType) async throws(NetworkError) -> (HTTPURLResponse?, Data?)
    func streamVideo(_ router: any VideoStreamableRouter,
                     interceptorType: InterceptorType,
                     responseHandler: @escaping @Sendable (HTTPURLResponse) -> Void,
                     dataHandler: @escaping DataStreamRequest.Handler<Data, Never>) -> DataStreamRequest
}

extension AsyncNetworkService {
    func request<T: Decodable & Sendable>(_ router: APIRouter,
                                          responseType: T.Type,
                                          interceptorType: InterceptorType = .networkWithToken) async throws(NetworkError) -> T {
        try await self.request(router, responseType: responseType, interceptorType: interceptorType)
    }
    
    func upload<T: Decodable & Sendable>(_ router: MultipartAPIRouter,
                                         responseType: T.Type,
                                         interceptorType: InterceptorType = .networkWithToken,
                                         progress: (@Sendable (Double) -> Void)? = nil) async throws(NetworkError) -> T {
        try await self.upload(router, responseType: responseType, interceptorType: interceptorType, progress: progress)
    }

    func download(_ router: DownloadAPIRouter,
                  interceptorType: InterceptorType = .networkWithToken) async throws(NetworkError) -> URL {
        try await self.download(router, interceptorType: interceptorType)
    }
    
    func downloadVideo(_ router: any APIRouter,
                       interceptorType: InterceptorType = .networkWithToken) async throws(NetworkError) -> (HTTPURLResponse?, Data?) {
        try await self.downloadVideo(router, interceptorType: interceptorType)
    }
    
    func streamVideo(_ router: any VideoStreamableRouter,
                     interceptorType: InterceptorType = .networkWithToken,
                     responseHandler: @escaping @Sendable (HTTPURLResponse) -> Void,
                     dataHandler: @escaping DataStreamRequest.Handler<Data, Never>) -> DataStreamRequest {
        return self.streamVideo(router,
                         interceptorType: interceptorType,
                         responseHandler: responseHandler,
                         dataHandler: dataHandler)
    }
}

protocol ReactiveNetworkService: Sendable {
    func request<T: Decodable & Sendable>(_ router: APIRouter,
                                          responseType: T.Type,
                                          interceptorType: InterceptorType) -> AnyPublisher<T, NetworkError>
}

extension ReactiveNetworkService {
    func request<T: Decodable & Sendable>(_ router: APIRouter,
                                          responseType: T.Type,
                                          interceptorType: InterceptorType = .networkWithToken) -> AnyPublisher<T, NetworkError> {
        self.request(router, responseType: responseType, interceptorType: interceptorType)
    }
}

