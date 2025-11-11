//
//  InterceptorType.swift
//  FlatBread
//
//  Created by hwan on 11/8/25.
//

import Foundation
import Alamofire

enum InterceptorType {
    case onlyNetworkRetrier
    case networkWithToken
    case onlyTokenInterceptor
    
    func wrappingInterceptor(networkRetrier: NetworkRetryRetrier,
                             tokenInterceptor: TokenInterceptor) -> Interceptor {
        switch self {
        case .onlyNetworkRetrier:
            Interceptor(adapters: [], retriers: [networkRetrier])
        case .networkWithToken:
            Interceptor(adapters: [tokenInterceptor], retriers: [networkRetrier, tokenInterceptor])
        case .onlyTokenInterceptor:
            Interceptor(adapters: [tokenInterceptor], retriers: [tokenInterceptor])
        }
    }
}
