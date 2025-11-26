//
//  Date+ShortVideoComment.swift
//  FlatBread
//
//  Created by 김민성 on 11/26/25.
//

import Foundation

extension Date {
    var asShortVideoCommentFormat: String {
        let timeDifference = Date.now.timeIntervalSince(self)
        if abs(timeDifference) > 60 * 60 * 24 {
            return self.toString(format: "yyyy-MM-dd")
        } else {
            return self.relativeTimeString()
        }
    }
}
