//
//  SideLongPressArea.swift
//  FlatBread
//
//  Created by 김민성 on 12/1/25.
//

import SwiftUI

struct SideLongPressArea: View {
    @Binding var isPressing: Bool
    
    let onPressingChanged: (Bool) -> Void
    let onTapGesture: () -> Void
    
    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .onLongPressGesture(
                minimumDuration: 0.3,
                maximumDistance: 10,
                perform: {
                    self.isPressing = true
                    onPressingChanged(isPressing)
                },
                onPressingChanged: { isPressing in
                    guard !isPressing else { return }
                    self.isPressing = isPressing
                    onPressingChanged(isPressing)
                }
            )
            .onTapGesture { _ in // 매개변수 타입: CGPoint
                onTapGesture()
            }
    }
}
