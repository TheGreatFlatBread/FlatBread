//
//  PaymentValidationResponseDTO.swift
//  FlatBread
//
//  Created by andev on 11/25/25.
//

import Foundation

struct PaymentValidationResponseDTO {
    let buyer_id: String?
    let post_id: String?
    let merchant_uid: String?
    let productName: String?
    let price: Int?
    let paidAt: String?
    let message: String?
}

nonisolated extension PaymentValidationResponseDTO: Decodable {}
