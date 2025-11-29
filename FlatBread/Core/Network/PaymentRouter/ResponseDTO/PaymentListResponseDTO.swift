//
//  PaymentListResponseDTO.swift
//  FlatBread
//
//  Created by 서준일 on 11/28/25.
//

import Foundation

struct PaymentListResponseDTO {
    let data: [PaymentResponseDTO]
}

struct PaymentResponseDTO {
    let buyerId: String
    let postId: String
    let merchantUid: String
    let productName: String
    let price: Int
    let paidAt: String
    
    enum CodingKeys: String, CodingKey {
        case buyerId = "buyer_id"
        case postId = "post_id"
        case merchantUid = "merchant_uid"
        case productName
        case price
        case paidAt
    }
}

nonisolated extension PaymentListResponseDTO: Decodable {}
nonisolated extension PaymentResponseDTO: Decodable {}
