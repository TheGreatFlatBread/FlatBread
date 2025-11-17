//
//  PostResponseDTO.swift
//  FlatBread
//
//  Created by hwan on 11/5/25.
//

import Foundation

struct PostListResponseDTO {
    let data: [PostResponseDTO]
    let next_cursor: String
}

struct PostGeoSearchListResponseDTO {
    let data: [PostResponseDTO]
}

struct PostResponseDTO {
    let post_id: String?
    let category: String?
    let title: String?
    let price: Int?
    let content: String?
    let value1: String?
    let value2: String?
    let value3: String?
    let value4: String?
    let value5: String?
    let value6: String?
    let value7: String?
    let value8: String?
    let value9: String?
    let value10: String?
    let createdAt: String?
    let creator: CreatorResponseDTO?
    let files: [String]
    let likes: [String]
    let likes2: [String]
    let buyers: [String]
    let hashTags: [String]
    let comment_count: Int?
    let geolocation: GeoLocationResponseDTO?
    let distance: Double?
}

struct CreatorResponseDTO {
    let user_id: String?
    let nick: String?
    let profileImage: String?
}

struct GeoLocationResponseDTO {
    let longitude: Double?
    let latitude: Double?
}

nonisolated extension PostResponseDTO: Decodable { }
nonisolated extension PostListResponseDTO: Decodable { }
nonisolated extension PostGeoSearchListResponseDTO: Decodable { }
nonisolated extension CreatorResponseDTO: Decodable { }
nonisolated extension GeoLocationResponseDTO: Decodable { }
