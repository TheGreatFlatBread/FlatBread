//
//  FBButton.swift
//  FlatBread
//
//  Created by andev on 4/2/26.
//

import SwiftUI

struct FBButton: View {
    enum Style {
        case primary
        case secondary
    }

    let title: String
    let style: Style
    let isLoading: Bool
    let isEnabled: Bool
    let height: CGFloat
    let cornerRadius: CGFloat
    let action: () -> Void

    init(
        title: String,
        style: Style = .primary,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        height: CGFloat = 50,
        cornerRadius: CGFloat = FBRadius.md,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.height = height
        self.cornerRadius = cornerRadius
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                } else {
                    Text(title)
                        .font(FBTypography.button)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .disabled(!isEnabled || isLoading)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isEnabled ? FBColor.Brand.primary : FBColor.State.disabled
        case .secondary:
            return FBColor.Background.input
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return FBColor.Text.inverse
        case .secondary:
            return FBColor.Text.primary
        }
    }
}
