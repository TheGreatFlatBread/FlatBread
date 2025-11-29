//
//  NicknameGenerator.swift
//  FlatBread
//
//  Created by 김민성 on 11/30/25.
//

import Foundation

struct NicknameGenerator {
    // 수식어 (형용사, 동사 등)
    private static let adjectives = [
        "온화한", "친절한", "멍때리는", "재빠른", "용감한", "소심한", "배고픈", "춤추는",
        "노래하는", "수상한", "시크한", "우아한", "엉뚱한", "잠꼬대하는", "열정적인",
        "게으른", "똑똑한", "수다스러운", "부끄러운", "사랑스러운", "무서운", "강력한",
        "비몽사몽한", "귀여운", "화려한", "침착한", "다급한", "행복한", "우울한", "즐거운"
    ]
    
    // 명사 (동물, 사물, 음식, 판타지 등)
    private static let nouns = [
        "코뿔소", "냉장고", "티라노사우르스", "바나나", "다람쥐", "개발자", "호랑이", "선인장",
        "마카롱", "외계인", "키보드", "쿼카", "나무늘보", "AI", "판다", "펭귄",
        "아메리카노", "비둘기", "고양이", "강아지", "노트북", "아이폰", "햄버거", "유니콘",
        "로봇", "해바라기", "돌멩이", "구름", "두더지", "북극곰"
    ]
    
    static func generate() -> String {
        let adj = adjectives.randomElement() ?? "행복한"
        let noun = nouns.randomElement() ?? "쿼카"
        return "\(adj) \(noun)"
    }
}
