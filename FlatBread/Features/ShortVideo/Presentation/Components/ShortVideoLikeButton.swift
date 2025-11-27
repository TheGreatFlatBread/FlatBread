//
//  ShortVideoLikeButton.swift
//  FlatBread
//
//  Created by 김민성 on 11/25/25.
//

import SwiftUI

struct ShortVideoLikeButton: View {
    @Binding var isLiked: Bool
    @Binding var count: Int
    
    var action: (Bool) -> Void
    
    @State private var showParticles: Bool = false
    
    private let baseForegroundStyle: Color = .white
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if showParticles {
                    ParticleEffect()
                }
                
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundStyle(isLiked ? .red : baseForegroundStyle)
                    .scaleEffect(isLiked ? 1.0 : 1.0)
                    .symbolEffect(.bounce, value: isLiked)
            }
            .frame(width: 50, height: 50) // 파티클이 퍼질 공간 확보
            
            Text("\(count)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(baseForegroundStyle)
                .contentTransition(.numericText(value: Double(count)))
        }
        .padding(10)
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap()
        }
    }
    
    // MARK: - Logic (Optimistic UI)
    private func handleTap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0)) {
            isLiked.toggle()
            
            if isLiked {
                count += 1
                showParticles = true
            } else {
                count -= 1
                showParticles = false
            }
        }
        
        // 파티클은 한 번 터지고 사라져야 하므로 잠시 후 상태 초기화
        if isLiked {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showParticles = false
            }
        }
        
        action(isLiked)
    }
}

// MARK: - Subview: 파티클 이펙트
struct ParticleEffect: View {
    @State private var scale: Double = 0.1
    
    var body: some View {
        ZStack {
            ForEach(0..<8) { index in
                Circle()
                    .fill(Color.red.opacity(0.6))
                    .frame(width: 6, height: 6)
                    // 원형으로 배치 후 밖으로 퍼지게 이동
                    .offset(y: -25) // 중심에서 시작 거리
                    .rotationEffect(.degrees(Double(index) * 45))
                    .scaleEffect(scale)
                    .opacity(2.0 - scale) // 퍼지면서 사라짐
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                self.scale = 2.5
            }
        }
    }
}

#Preview {
    @Previewable @State var isLiked: Bool = false
    @Previewable @State var count: Int = 0
    ShortVideoLikeButton(
        isLiked: $isLiked,
        count: $count) { newValue in
            print("선택됨: \(newValue)")
        }
}
