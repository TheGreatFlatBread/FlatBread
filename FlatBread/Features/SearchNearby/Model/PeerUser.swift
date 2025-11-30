//
//  PeerUser.swift
//  FlatBread
//
//  Created by 김민성 on 11/27/25.
//

import Foundation
import MultipeerConnectivity

struct PeerUser: Identifiable, Equatable {
    var id: String { return fbUserID }
    let fbUserID: String
    let mcPeerID: MCPeerID
    let displayImageName: String
    
    let distanceFactor: CGFloat
    let angle: Double
    
    init(mcPeerID: MCPeerID, fbUserID: String) {
        self.fbUserID = fbUserID
        self.mcPeerID = mcPeerID
        // 이미지 및 위치 랜덤 배정
        let images = ["face.smiling", "star.fill", "moon.fill", "sun.max.fill", "heart.fill", "pawprint.fill"]
        self.displayImageName = images.randomElement() ?? "person.fill"
        self.distanceFactor = CGFloat.random(in: 0.3...0.85)
        self.angle = Double.random(in: 0...360)
    }
    
    static func == (lhs: PeerUser, rhs: PeerUser) -> Bool {
        return lhs.mcPeerID == rhs.mcPeerID
    }
}
