//
//  ImageFileManager.swift
//  FlatBread
//
//  Created by hwan on 11/14/25.
//

import UIKit

final class ImageFileManager {
    static let shared = ImageFileManager()

    private init() {}

    private var chatImagesDirectory: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let chatImagesDir = documentsDirectory.appendingPathComponent("ChatImages", isDirectory: true)

        if !FileManager.default.fileExists(atPath: chatImagesDir.path) {
            try? FileManager.default.createDirectory(at: chatImagesDir, withIntermediateDirectories: true)
        }

        return chatImagesDir
    }

    func saveImage(_ image: UIImage, compressionQuality: CGFloat = 0.75, maxSize: CGFloat = 720) -> String? {
        let originalSize = image.size
        let originalData = image.jpegData(compressionQuality: 1.0)
        let originalSizeInMB = originalData?.sizeInMiB ?? 0

        let resizedImage = resizeImage(image, maxSize: maxSize)

        guard let imageData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }

        #if DEBUG
        let compressedSizeInMB = imageData.sizeInMiB
        let compressionRatio = (1.0 - compressedSizeInMB / originalSizeInMB) * 100
        print("""
           이미지 저장:
           원본: \(Int(originalSize.width))x\(Int(originalSize.height)) (\(String(format: "%.2f", originalSizeInMB))MB)
           압축: \(Int(resizedImage.size.width))x\(Int(resizedImage.size.height)) (\(String(format: "%.2f", compressedSizeInMB))MB)
           절감: \(String(format: "%.1f", compressionRatio))%
        """)
        #endif

        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = chatImagesDirectory.appendingPathComponent(fileName)

        do {
            try imageData.write(to: fileURL)
            return fileURL.absoluteString
        } catch {
            return nil
        }
    }
    
    func saveImages(_ images: [UIImage], compressionQuality: CGFloat = 0.75, maxSize: CGFloat = 720) -> [String] {
        return images.compactMap { saveImage($0, compressionQuality: compressionQuality, maxSize: maxSize) }
    }

    func saveImageData(_ imageData: Data, compressionQuality: CGFloat = 0.75, maxSize: CGFloat = 720) -> String? {
        guard let image = UIImage(data: imageData) else { return nil }
        return saveImage(image, compressionQuality: compressionQuality, maxSize: maxSize)
    }

    func saveImagesData(_ imagesData: [Data], compressionQuality: CGFloat = 0.75, maxSize: CGFloat = 720) -> [String] {
        return imagesData.compactMap { saveImageData($0, compressionQuality: compressionQuality, maxSize: maxSize) }
    }

    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size

        if size.width <= maxSize && size.height <= maxSize {
            return image
        }

        let ratio: CGFloat
        if size.width > size.height {
            ratio = maxSize / size.width
        } else {
            ratio = maxSize / size.height
        }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resizedImage
    }

    func loadImage(from urlString: String) -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        guard let imageData = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: imageData)
    }

    func deleteImage(at urlString: String) {
        guard let url = URL(string: urlString) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    func deleteImages(at urlStrings: [String]) {
        urlStrings.forEach { deleteImage(at: $0) }
    }

    func clearAllChatImages() {
        try? FileManager.default.removeItem(at: chatImagesDirectory)
    }

    func getFileSize(urlString: String) -> Double? {
        guard let url = URL(string: urlString) else { return nil }
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) else { return nil }
        guard let fileSize = attributes[.size] as? Int64 else { return nil }
        return fileSize.sizeInMiB
    }

    func getTotalChatImagesSize() -> Double {
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(
            at: chatImagesDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }

        let totalBytes = fileURLs.reduce(Int64(0)) { total, url in
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) else { return total }
            guard let fileSize = attributes[.size] as? Int64 else { return total }
            return total + fileSize
        }
        
        return totalBytes.sizeInMiB
    }

    func getChatImagesCount() -> Int {
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(
            at: chatImagesDirectory,
            includingPropertiesForKeys: nil
        ) else { return 0 }
        return fileURLs.count
    }

    func cleanupOldTempFiles(olderThan days: Int = 1) {
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(
            at: chatImagesDirectory,
            includingPropertiesForKeys: [.creationDateKey]
        ) else { return }

        let cutoffDate = Date.now.addingTimeInterval(-TimeInterval(days * 24 * 60 * 60))
        var deletedCount = 0
        var deletedSize: Int64 = 0

        for fileURL in fileURLs {
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                  let creationDate = attributes[.creationDate] as? Date,
                  let fileSize = attributes[.size] as? Int64 else {
                continue
            }
            if creationDate < cutoffDate {
                try? FileManager.default.removeItem(at: fileURL)
                deletedCount += 1
                deletedSize += fileSize
            }
        }
        
        #if DEBUG
        if deletedCount > 0 {
            let deletedSizeInMB = deletedSize.sizeInMiB
            print("""
               Temp file 정리 완료:
               삭제된 파일: \(deletedCount)개
               확보된 용량: \(String(format: "%.2f", deletedSizeInMB))MB
            """)
        }
        #endif
    }
    
    func printChatImagesDirectory() {
        print("채팅 이미지 저장 경로: \(chatImagesDirectory.path)")
        print("파일 개수: \(getChatImagesCount())개")
        print("총 용량: \(String(format: "%.2f", getTotalChatImagesSize()))MB")
    }
}
