//
//  NetworkService.swift
//  FlatBread
//
//  Created by hawn on 11/6/25.
//

import Foundation
import Alamofire
import Combine

final class DefaultNetworkService: AsyncNetworkService {
    private let session: Session
    private let tokenInterceptor: TokenInterceptor
    private let networkRetrier: NetworkRetryRetrier
    
    init(session: Session = .default,
         tokenInterceptor: TokenInterceptor,
         networkRetrier: NetworkRetryRetrier) {
        self.session = session
        self.tokenInterceptor = tokenInterceptor
        self.networkRetrier = networkRetrier
    }

    func request<T: Decodable & Sendable>(_ router: APIRouter, responseType: T.Type, interceptorType: InterceptorType) async throws(NetworkError) -> T {
        do {
            let interceptor = interceptorType.wrappingInterceptor(
                networkRetrier: networkRetrier,
                tokenInterceptor: tokenInterceptor
            )
            let request = session.request(router, interceptor: interceptor)
            return try await request
                .validate(statusCode: 200..<300)
                .serializingDecodable(T.self, emptyResponseCodes: [200])
                .value
        } catch let afError as AFError {
            throw NetworkError.from(afError)
        } catch {
            throw NetworkError.from(error)
        }
    }

    func upload<T: Decodable & Sendable>(_ router: MultipartAPIRouter,
                                         responseType: T.Type,
                                         interceptorType: InterceptorType,
                                         progress: (@Sendable (Double) -> Void)? = nil) async throws(NetworkError) -> T {
        do {
            let interceptor = interceptorType.wrappingInterceptor(
                networkRetrier: networkRetrier,
                tokenInterceptor: tokenInterceptor
            )
            let uploadTask = session.upload(
                multipartFormData: router.multipartFormData,
                with: router,
                interceptor: interceptor
            )
                .uploadProgress { uploadProgress in
                    progress?(uploadProgress.fractionCompleted)
                }
                .validate(statusCode: 200..<300)
                .serializingDecodable(T.self)

            let value = try await uploadTask.value
            return value
        } catch let afError as AFError {
            throw NetworkError.from(afError)
        } catch {
            throw NetworkError.from(error)
        }
    }

    func download(_ router: DownloadAPIRouter, interceptorType: InterceptorType) async throws(NetworkError) -> URL {
        do {
            let interceptor = interceptorType.wrappingInterceptor(
                networkRetrier: networkRetrier,
                tokenInterceptor: tokenInterceptor
            )
            let downloadTask = session.download(router, interceptor: interceptor, to: router.destination)
                .validate(statusCode: 200..<300)
                .serializingDownloadedFileURL()

            let fileURL = try await downloadTask.value
            return fileURL
        } catch let afError as AFError {
            throw NetworkError.from(afError)
        } catch {
            throw NetworkError.from(error)
        }
    }
    
    func downloadVideo(_ router: any APIRouter, interceptorType: InterceptorType) async throws(NetworkError) -> (HTTPURLResponse?, Data?) {
        let interceptor = interceptorType.wrappingInterceptor(
            networkRetrier: networkRetrier,
            tokenInterceptor: tokenInterceptor
        )
        
        let request = session.request(router, interceptor: interceptor)
        let afResponse = await request
            .validate(statusCode: 200..<300)
            .serializingData()
            .response
        
        switch afResponse.result {
        case .success(let data):
            return (afResponse.response, data)
        case .failure(let afError):
            throw NetworkError.from(afError)
        }
    }
    
    func streamVideo(
        _ router: any VideoStreamableRouter,
        interceptorType: InterceptorType,
        responseHandler: @escaping (HTTPURLResponse) -> Void,
        dataHandler: @escaping DataStreamRequest.Handler<Data, Never>
    ) -> DataStreamRequest {
        let interceptor = interceptorType.wrappingInterceptor(
            networkRetrier: networkRetrier,
            tokenInterceptor: tokenInterceptor
        )
        return session.streamRequest(router, interceptor: interceptor)
            .onHTTPResponse(perform: responseHandler)
            .responseStream(stream: dataHandler)
    }
}

extension DefaultNetworkService: ReactiveNetworkService {
    func request<T: Decodable & Sendable>(_ router: any APIRouter,
                                          responseType: T.Type,
                                          interceptorType: InterceptorType) -> AnyPublisher<T, NetworkError> {
        let interceptor = interceptorType.wrappingInterceptor(
            networkRetrier: networkRetrier,
            tokenInterceptor: tokenInterceptor
        )
        let request = session.request(router, interceptor: interceptor)
        return request
            .validate(statusCode: 200..<300)
            .publishDecodable(type: T.self)
            .value()
            .mapError { afError in
                NetworkError.from(afError)
            }
            .eraseToAnyPublisher()
    }
}
