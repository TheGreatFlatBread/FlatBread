//
//  PostResponseDTO.swift
//  FlatBread
//
//  Created by hwan on 11/5/25.
//

import Foundation

struct PostListResponseDTO: Decodable {
    let data: [PostResponseDTO]
    let next_cursor: String
}

struct PostResponseDTO: Decodable {
    var post_id: String?
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
    var createdAt: String?
    var creator: CreatorResponseDTO?
    var files: [String]
    var likesV1: [String]
    var likesV2: [String]
    var buyers: [String]
    var hashTags: [String]
    var comment_count: Int?
    var geolocation: GeoLocationResponseDTO?
    var distance: Double?
}

struct CreatorResponseDTO: Decodable {
    var user_id: String?
    var nick: String?
    var profileImage: String?
}

struct GeoLocationResponseDTO: Decodable {
    var longitude: Double?
    var latitude: Double?
}
