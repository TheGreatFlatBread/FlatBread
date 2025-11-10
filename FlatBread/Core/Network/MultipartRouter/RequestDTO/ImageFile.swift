//
//  ImageFile.swift
//  FlatBread
//
//  Created by hwan on 11/5/25.
//

import Foundation

struct ImageFile {
    let data: Data
    let fileName: String
    let mimeType: String

    init(
        data: Data,
        fileName: String,
        mimeType: String = "image/jpeg"
    ) {
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
    }
}
