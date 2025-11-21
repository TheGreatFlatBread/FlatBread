//
//  Movie.swift
//  FlatBread
//
//  Created by 김민성 on 11/20/25.
//

import SwiftUI
import Photos

// Transferable 프로토콜을 위한 헬퍼 구조체
struct Movie: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(
            contentType: .movie,
            exporting: { movie in SentTransferredFile(movie.url) },
            importing: { received in
                // 갤러리의 파일을 앱의 임시 폴더로 복사 (압축 전)
                let copy = FileManager.default.temporaryDirectory.appending(path: "original.mp4")
                if FileManager.default.fileExists(atPath: copy.path) {
                    try? FileManager.default.removeItem(at: copy)
                }
                try FileManager.default.copyItem(at: received.file, to: copy)
                return Self(url: copy)
            }
        )
    }
}
