//
//  PostRequestDTO.swift
//  FlatBread
//
//  Created by hwan on 11/5/25.
//

import Foundation

struct PostUploadRequestDTO {
    var category: String?
    var title: String?
    var price: Int?
    var content: String?
    var value1: String?
    var value2: String?
    var value3: String?
    var value4: String?
    var value5: String?
    var value6: String?
    var value7: String?
    var value8: String?
    var value9: String?
    var value10: String?
    var files: [String]
    var longitude: Double
    var latitude: Double
}

extension PostUploadRequestDTO: Encodable { }
