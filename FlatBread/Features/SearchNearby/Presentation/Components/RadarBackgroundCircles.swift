//
//  RadarBackgroundCircles.swift
//  FlatBread
//
//  Created by 김민성 on 11/29/25.
//

import SwiftUI

struct RadarBackgroundCircles: View {
    var body: some View {
        ZStack {
            ForEach(1..<5) { i in
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    .scaleEffect(CGFloat(i) * 0.25)
            }
        }
    }
}

#Preview {
    RadarBackgroundCircles()
}
