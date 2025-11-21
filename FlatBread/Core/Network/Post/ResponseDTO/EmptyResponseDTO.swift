//
//  EmptyResponseDTO.swift
//  FlatBread
//
//  Created by hwan on 11/19/25.
//

import Foundation
import Alamofire

nonisolated
struct EmptyEntity: Codable, EmptyResponse {
    
    static func emptyValue() -> EmptyEntity {
        return EmptyEntity.init()
    }
}
