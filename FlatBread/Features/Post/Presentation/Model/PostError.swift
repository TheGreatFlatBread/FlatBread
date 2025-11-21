//
//  PostError.swift
//  FlatBread
//
//  Created by hwan on 11/19/25.
//

import Foundation

enum PostError {
    case uploadImageFailed(NetworkError)
}

enum PostUploadError: LocalizedError {
    case imageConversionFailed
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "이미지 변환에 실패했습니다."
        case .uploadFailed:
            return "게시물 업로드에 실패했습니다."
        }
    }
}
