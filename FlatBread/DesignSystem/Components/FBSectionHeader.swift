//
//  FBSectionHeader.swift
//  FlatBread
//
//  Created by andev on 4/2/26.
//

import SwiftUI

struct FBSectionHeader: View {
    enum Style {
        case large
        case regular
        case small
    }

    let title: String
    var style: Style = .small

    var body: some View {
        Text(title)
            .font(font)
            .foregroundStyle(FBColor.Text.primary)
    }

    private var font: Font {
        switch style {
        case .large:
            return FBTypography.sectionLarge
        case .regular:
            return FBTypography.section
        case .small:
            return .headline
        }
    }
}
