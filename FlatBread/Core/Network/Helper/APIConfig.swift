//
//  APIConfig.swift
//  FlatBread
//
//  Created by hwan on 11/5/25.
//

import Foundation

enum APIConfig {
    private static let info = Bundle.main.infoDictionary
    private static let domain: String = if let domain = info?["domain"] as? String {
        domain
    } else {
        fatalError("required base_url")
    }
    static let apikey: String = if let api_key = info?["api_key"] as? String {
        api_key
    } else {
        fatalError("required api_key")
    }
    static let productID: String = if let id = info?["product_id"] as? String {
        id
    } else {
        fatalError("required product_id")
    }
    static let baseURL: String = "http://" + domain + "/v1"
}
