//
//  FindNearbyPeerIconView.swift
//  FlatBread
//
//  Created by 김민성 on 11/29/25.
//

import MultipeerConnectivity
import SwiftUI

struct FindNearbyPeerIconView: View {
    let peer: PeerUser
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                Image(systemName: peer.displayImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
                    .foregroundColor(.orange)
            }
            
            Text(peer.mcPeerID.displayName)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .transition(.scale.combined(with: .opacity))
    }
}

//#Preview {
//    FindNearbyPeerIconView()
//}
