//
//  EmailValidationResponseDTO.swift
//  FlatBread
//
//  Created by hwan on 11/6/25.
//

import Foundation

struct EmailValidationResponseDTO {
    var email: String?
}

nonisolated extension EmailValidationResponseDTO: Decodable { }
