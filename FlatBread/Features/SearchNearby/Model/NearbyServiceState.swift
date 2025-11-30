//
//  NearbyServiceState.swift
//  FlatBread
//
//  Created by 김민성 on 11/29/25.
//

import Foundation

extension NearbyService {
    
    enum NearbyServiceState: Equatable {
        case initializing               // 초기화 중
        case idle                       // 대기 중 (탐색/광고)
        case inviting(PeerUser)         // 내가 요청 보냄
        case responding(PeerUser)       // 남이 나에게 요청 보냄 (Alert 표시)
        case connecting(PeerUser)       // 연결 시도 중 (수락/거절 버튼 누른 직후)
        case connected(PeerUser)        // 물리적 연결 완료 (데이터 교환 단계)
        case fetchingProfile(String)    // 프로필 정보 가져오는 중
        case chatting(to: String)       // 채팅 시작 (MPC 종료됨)
        
        var isBusy: Bool {
            // idle이 아니면 무언가 하고 있는 상태
            if case .idle = self { return false }
            if case .initializing = self { return false }
            return true
        }
    }
    
}
