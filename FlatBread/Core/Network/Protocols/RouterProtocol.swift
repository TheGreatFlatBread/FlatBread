//
//  RouterProtocol.swift
//  FlatBread
//
//  Created by hwan on 11/6/25.
//

import Foundation
import Alamofire

protocol APIRouter: URLRequestConvertible {
    var baseURL: URL { get }
    var method: HTTPMethod { get }
    var path: String { get }
    var headers: HTTPHeaders { get }
}

protocol MultipartAPIRouter: APIRouter {
    var multipartFormData: MultipartFormData { get }
}

protocol DownloadAPIRouter: APIRouter {
    var destination: DownloadRequest.Destination { get }
}

protocol ParameterAPIRouter: APIRouter {
    var parameters: Parameters? { get }
    var encoding: ParameterEncoding { get }
}

typealias VideoStreamableRouter = APIRouter & URLConvertible
