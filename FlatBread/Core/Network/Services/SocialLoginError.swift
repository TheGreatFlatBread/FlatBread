//
//  SocialLoginError.swift
//  FlatBread
//
//  Created by 김민성 on 11/12/25.
//

import Foundation

enum SocialLoginError: LocalizedError {
    
    case appleIdTokenNil
    case appleIDTokenEncodingFailed
    case sessionExpired
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .appleIdTokenNil:
            return "애플 로그인 id token 값이 비어있음."
        case .appleIDTokenEncodingFailed:
            return "애플 로그인 id token Data를 String으로 encoding 실패"
        case .sessionExpired:
            return "사용자 세션이 만료됨"
        case .unknown(let error):
            return "소셜 로그인 실패: \(error.localizedDescription)"
        }
    }
    
}
