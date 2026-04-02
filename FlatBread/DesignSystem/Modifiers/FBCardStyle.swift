//
//  FBCardStyle.swift
//  FlatBread
//
//  Created by andev on 4/2/26.
//

import SwiftUI

struct FBCardStyle: ViewModifier {
    let cornerRadius: CGFloat
    let fill: Color
    let border: Color
    let borderWidth: CGFloat
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowX: CGFloat
    let shadowY: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(border, lineWidth: borderWidth)
            }
            .shadow(color: shadowColor, radius: shadowRadius, x: shadowX, y: shadowY)
    }
}

extension View {
    func fbCardStyle(
        cornerRadius: CGFloat = FBRadius.xl,
        fill: Color = FBColor.Background.primary,
        border: Color = .black.opacity(0.05),
        borderWidth: CGFloat = 1,
        shadowColor: Color = .black.opacity(0.06),
        shadowRadius: CGFloat = 8,
        shadowX: CGFloat = 0,
        shadowY: CGFloat = 2
    ) -> some View {
        modifier(
            FBCardStyle(
                cornerRadius: cornerRadius,
                fill: fill,
                border: border,
                borderWidth: borderWidth,
                shadowColor: shadowColor,
                shadowRadius: shadowRadius,
                shadowX: shadowX,
                shadowY: shadowY
            )
        )
    }
}
