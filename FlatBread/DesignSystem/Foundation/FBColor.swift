//
//  FBColor.swift
//  FlatBread
//
//  Created by andev on 4/2/26.
//

import SwiftUI

enum FBColor {
    enum Brand {
        static let primary = Color("juhwang")
    }

    enum Text {
        static let primary = Color.primary
        static let secondary = Color.secondary
        static let inverse = Color.white
    }

    enum Background {
        static let primary = Color(.systemBackground)
        static let secondary = Color(.secondarySystemBackground)
        static let input = Color(.systemGray6)
    }

    enum Border {
        static let subtle = Color(.systemGray4)
    }

    enum State {
        static let success = Color.green
        static let error = Color.red
        static let disabled = Color.gray.opacity(0.3)
    }
}
