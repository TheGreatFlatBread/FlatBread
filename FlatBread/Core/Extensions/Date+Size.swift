//
//  Data+.swift
//  FlatBread
//
//  Created by hwan on 11/16/25.
//

import Foundation

extension Data {
    var sizeInMiB: Double { Double(self.count) / 1024.0 / 1024.0 }
}

extension Int64 {
    var sizeInMiB: Double { Double(self) / 1024.0 / 1024.0 }
}
