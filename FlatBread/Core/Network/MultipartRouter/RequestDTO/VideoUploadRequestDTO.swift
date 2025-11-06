//
//  VideoUploadRequestDTO.swift
//  FlatBread
//
//  Created by hwan on 11/5/25.
//

import Foundation

struct VideoUploadRequestDTO {
    let files: [VideoFile]

    init(files: [VideoFile]) {
        self.files = files
    }

    init(videos: [Data]) {
        self.files = videos.enumerated().map { index, data in
            VideoFile(
                data: data,
                fileName: "video\(index).mp4"
            )
        }
    }

    init(videoParts: [Data]) {
        self.files = videoParts.enumerated().map { index, data in
            VideoFile(
                data: data,
                fileName: "video_part\(index).mp4"
            )
        }
    }

    init(videos: [Data], fileNames: [String]) {
        self.files = videos.enumerated().map { index, data in
            VideoFile(
                data: data,
                fileName: fileNames[index]
            )
        }
    }
}
