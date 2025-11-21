//
//  VideoUploadViewModel.swift
//  FlatBread
//
//  Created by 김민성 on 11/21/25.
//

import Combine
import Foundation
import SwiftUI
import PhotosUI

final class VideoUploadViewModel: ObservableObject {
    
    @Published var selectedItem: PhotosPickerItem?
    
    // UI
    @Published var statusMessage: String = "비디오를 선택해주세요."
    @Published var originalSizeText: String = "0 MB"
    @Published var compressedSizeText: String = "0 MB"
    @Published var isProcessing: Bool = false
    
    @Published var compressedVideoData: Data?
    
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    
    
    // MARK: - Computeds
    
    var isUnderLimit: Bool {
        guard let data = compressedVideoData else { return false }
        return Double(data.count) / (1024 * 1024) <= 10.0
    }
    
    /// 업로드 가능 여부
    ///
    /// 다음 조건을 모두 만족하는 경우에만 `true`반환
    ///
    /// - 압축된 `Data`가 `nil`이 아님
    /// - 압축 진행 중이 아님
    /// - 용량 한도를 초과하지 않음.
    var canUpload: Bool {
        return compressedVideoData != nil && !isProcessing && isUnderLimit
    }
    
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        $selectedItem
            .sink { [weak self] newPickedItem in
                guard let self, let newPickedItem else { return }
                processSelectedVideo(item: newPickedItem)
            }
            .store(in: &cancellables)
    }
    
}

// MARK: - Fetching & Compressing
private extension VideoUploadViewModel {
    
    private func processSelectedVideo(item: PhotosPickerItem) {
        isProcessing = true
        statusMessage = "파일 불러오는 중..."
        compressedVideoData = nil
        compressedSizeText = "-"
        
        item.loadTransferable(type: Movie.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let movie):
                    // 원본 용량 체크
                    guard let movie else {
                        print("⚠️ movie is nil")
                        return
                    }
                    if let attr = try? FileManager.default.attributesOfItem(atPath: movie.url.path),
                       let fileSize = attr[.size] as? UInt64 {
                        self.originalSizeText = String(format: "%.2f MB", Double(fileSize) / (1024 * 1024))
                    }
                    
                    // 압축 시작
                    self.statusMessage = "압축 진행 중..."
                    self.compressVideo(inputURL: movie.url)
                    
                case .failure(let error):
                    self.statusMessage = "로드 실패: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
    
    // MARK: - compressVideo
    private func compressVideo(inputURL: URL) {
        let urlAsset = AVURLAsset(url: inputURL)
        
        // 10MB 제한을 맞추기 위해 540p (HD) 프리셋 사용
        guard let exportSession = AVAssetExportSession(
            asset: urlAsset,
            presetName: AVAssetExportPreset1280x720
        ) else {
            statusMessage = "압축 세션 생성 실패"
            isProcessing = false
            return
        }
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mp4")
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true // Fast Start 적용
        exportSession.fileLengthLimit = 10 * 1024 * 1024
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    do {
                        let data = try Data(contentsOf: outputURL)
                        self.compressedVideoData = data
                        let mbSize = Double(data.count) / (1024 * 1024)
                        self.compressedSizeText = String(format: "%.2f MB", mbSize)
                        
                        if mbSize > 10.0 {
                            self.statusMessage = "압축했지만 10MB를 초과합니다."
                        } else {
                            self.statusMessage = "준비 완료"
                        }
                    } catch {
                        self.statusMessage = "데이터 변환 실패"
                    }
                case .failed:
                    self.statusMessage = "압축 실패: \(exportSession.error?.localizedDescription ?? "알 수 없음")"
                default:
                    self.statusMessage = "알 수 없는 상태"
                }
                self.isProcessing = false
            }
        }
    }
    
}


// MARK: - Uploading
extension VideoUploadViewModel {
    
    func uploadVideo() {
        guard let videoData = compressedVideoData else { return }
        
        print("--- 업로드 시작 ---")
        print("파일 크기: \(videoData.count) bytes")
        
        let videoFile = VideoFile(data: videoData, fileName: "videoTest")
        let videoUploadRequestDTO = VideoUploadRequestDTO(files: [videoFile])
        let multipardAPIRouter = MultipartRouter.uploadVideos(request: videoUploadRequestDTO)
        
        Task {
            do {
                let fileUploadResponse = try await networkService.upload(
                    multipardAPIRouter,
                    responseType: FileUploadResponseDTO.self
                ) { progress in
                    print("progress: \(progress)")
                }
                print("업로드 성공: \(fileUploadResponse.files)")
                
            } catch {
                print("동영상 업로드 실패: \(error.localizedDescription)")
            }
        }
    }
    
}
