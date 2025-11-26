//
//  PaymentValidationRequestDTO.swift
//  FlatBread
//
//  Created by andev on 11/25/25.
//

import Foundation

struct PaymentValidationRequestDTO {
    let imp_uid: String
    let post_id: String
}

nonisolated extension PaymentValidationRequestDTO: Encodable {}
