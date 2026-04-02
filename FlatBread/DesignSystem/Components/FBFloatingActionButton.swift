//
//  FBFloatingActionButton.swift
//  FlatBread
//
//  Created by andev on 4/2/26.
//

import SwiftUI

struct FBFloatingActionButton: View {
    let systemImage: String
    var size: CGFloat = 56
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(FBColor.Text.inverse)
                .frame(width: size, height: size)
                .background(FBColor.Brand.primary)
                .clipShape(Circle())
                .shadow(radius: 8)
        }
    }
}

