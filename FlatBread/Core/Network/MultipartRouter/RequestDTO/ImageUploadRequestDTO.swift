//
//  ImageUploadRequestDTO.swift
//  FlatBread
//
//  Created by hwan on 11/5/25.
//

import Foundation

nonisolated
struct ImageUploadRequestDTO {
    let files: [ImageFile]

    init(files: [ImageFile]) {
        self.files = files
    }

    init(images: [Data]) {
        self.files = images.enumerated().map { index, data in
            ImageFile(
                data: data,
                fileName: "image\(index).jpg"
            )
        }
    }

    init(images: [Data], fileNames: [String]) {
        self.files = images.enumerated().map { index, data in
            ImageFile(
                data: data,
                fileName: fileNames[index]
            )
        }
    }

    init(fileURLs: [URL]) {
        self.files = fileURLs.map { url in
            ImageFile(fileURL: url)
        }
    }

    init(fileURLs: [String]) {
        self.files = fileURLs.compactMap { urlString in
            guard let url = URL(string: urlString) else { return nil }
            return ImageFile(fileURL: url)
        }
    }
}
