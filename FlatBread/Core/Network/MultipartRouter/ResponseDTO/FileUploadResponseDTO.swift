//
//  FileUploadResponseDTO.swift
//  FlatBread
//
//  Created by hwan on 11/6/25.
//

import Foundation

struct FileUploadResponseDTO {
    let files: [String]
}

nonisolated extension FileUploadResponseDTO: Decodable { }
