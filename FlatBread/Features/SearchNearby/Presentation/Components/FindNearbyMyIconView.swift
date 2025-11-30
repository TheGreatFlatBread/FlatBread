//
//  FindNearbyMyIconView.swift
//  FlatBread
//
//  Created by 김민성 on 11/29/25.
//

import SwiftUI

struct FindNearbyMyIconView: View {
    let id: String
    var body: some View {
        ZStack {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 60, height: 60)
                    .shadow(radius: 2)
                
                Image(systemName: "iphone.gen3")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
                    .foregroundColor(.gray)
            }
            
            // 펄스 효과 (내가 여기 있음을 알리는 애니메이션)
            Circle()
                .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                .frame(width: 60, height: 60)
                .scaleEffect(1.2)
                .opacity(0)
                .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: true)
        }
    }
}

#Preview {
    FindNearbyMyIconView(id: "내 이름")
}
