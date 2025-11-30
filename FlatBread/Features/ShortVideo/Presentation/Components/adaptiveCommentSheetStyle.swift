//
//  adaptiveCommentSheetStyle.swift
//  FlatBread
//
//  Created by 김민성 on 11/30/25.
//

import SwiftUI

extension View {
    @ViewBuilder
    var adaptiveCommentSheetStyle: some View {
        if #available(iOS 26.0, *) {
            clipShape(ContainerRelativeShape())
        } else {
            presentationCornerRadius(30)
        }
    }
}
