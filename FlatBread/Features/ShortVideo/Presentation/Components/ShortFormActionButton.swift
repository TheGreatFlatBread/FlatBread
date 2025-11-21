//
//  ShortFormActionButton.swift
//  FlatBread
//
//  Created by 김민성 on 11/21/25.
//

import SwiftUI

struct ShortFormActionButton: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .shadow(radius: 2)
            Text(text)
                .font(.caption2).bold()
                .shadow(radius: 1)
        }
    }
}

#Preview {
    ShortFormActionButton(icon: "heart.fill", text: "Like")
}
