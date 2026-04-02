//
//  FBSectionHeader.swift
//  FlatBread
//
//  Created by andev on 4/2/26.
//

import SwiftUI

struct FBSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(FBColor.Text.primary)
    }
}

