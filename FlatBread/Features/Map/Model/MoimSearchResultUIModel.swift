//
//  MoimSearchResultUIModel.swift
//  FlatBread
//
//  Created by 김민성 on 11/18/25.
//

import Foundation

struct MoimSearchResultUIModel: Identifiable {
    let id: String
    let title: String?
    let content: String
    let category: MoimCategory
    let member: [String]
    let location: String // ex) 서울 관악구
    var imageURL: String?
}


extension PostResponseDTO {
    
    var asSearchResultUIModel: MoimSearchResultUIModel? {
        guard let id = post_id,
              let category = MoimCategory(rawValue: self.category!) else {
            return nil
        }
        return .init(
            id: id,
            title: self.title,
            content: self.content ?? "",
            category: category,
            member: likes2, // 임시로 likes2 로 구현. 추후 결제 기능 붙이면 결제한 사람으로 변경
            location: self.value1 ?? "",
            imageURL: files.first
        )
    }
    
}
