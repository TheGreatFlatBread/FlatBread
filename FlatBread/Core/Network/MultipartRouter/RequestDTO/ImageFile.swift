//
//  ImageFile.swift
//  FlatBread
//
//  Created by hwan on 11/5/25.
//

import Foundation

nonisolated
struct ImageFile {
    let data: Data?
    let fileURL: URL?
    let fileName: String
    let mimeType: String

    init(
        data: Data,
        fileName: String,
        mimeType: String = "image/jpeg"
    ) {
        self.data = data
        self.fileURL = nil
        self.fileName = fileName
        self.mimeType = mimeType
    }

    init(
        fileURL: URL,
        fileName: String? = nil,
        mimeType: String = "image/jpeg"
    ) {
        self.data = nil
        self.fileURL = fileURL
        self.fileName = fileName ?? fileURL.lastPathComponent
        self.mimeType = mimeType
    }
}
