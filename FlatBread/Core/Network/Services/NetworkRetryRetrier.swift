//
//  NetworkRetryRetrier.swift
//  FlatBread
//
//  Created by hwan on 11/8/25.
//

import Foundation
import Alamofire

struct NetworkRetryRetrier: RequestRetrier {
    private let maxRetryCount: Int
    private let retryDelay: TimeInterval
    
    init(maxRetryCount: Int = 2, retryDelay: TimeInterval = 1) {
        self.maxRetryCount = maxRetryCount
        self.retryDelay = retryDelay
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard request.retryCount < maxRetryCount else {
            completion(.doNotRetry)
            return
        }
        
        if let afError = error as? AFError {
            switch afError {
            case .sessionTaskFailed(let urlError as NSError):
                switch urlError.code {
                case NSURLErrorTimedOut,
                    NSURLErrorCannotFindHost,
                    NSURLErrorCannotConnectToHost,
                    NSURLErrorNetworkConnectionLost,
                NSURLErrorNotConnectedToInternet:
                    completion(.retryWithDelay(retryDelay))
                    return
                default:
                    break
                }
            default:
                break
            }
        }
        completion(.doNotRetry)
    }
}
