//
//  ImageUploadRequestDTO.swift
//  FlatBread
//
//  Created by hwan on 11/5/25.
//

import Foundation

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
}
