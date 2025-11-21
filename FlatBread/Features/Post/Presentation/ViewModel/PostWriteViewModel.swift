//
//  PostWriteViewModel.swift
//  FlatBread
//
//  Created by hwan on 11/18/25.
//

import Foundation
import SwiftUI
import Combine
import Kingfisher

@MainActor
final class PostWriteViewModel: ObservableObject {
    @Published var selectedCategory: PostType = .free
    @Published var content: String = ""
    @Published var selectedImageURLs: [String] = []  // temp file URLs
    @Published var hasSchedule = false
    @Published var scheduleDate = Date.now
    @Published var scheduleTitle: String = ""
    @Published var scheduleLocation: String = ""
    @Published var maxParticipants: Int = 10

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var errorActions: [ErrorAction] = []

    private let networkService: AsyncNetworkService = NetworkServiceFactory.shared.makeNetworkService()
    private let moimId: String
    private let postToEdit: PostUIModel?

    var isEditMode: Bool {
        postToEdit != nil
    }

    var canPost: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(moimId: String, postToEdit: PostUIModel? = nil) {
        self.moimId = moimId
        self.postToEdit = postToEdit

        if let post = postToEdit {
            self.selectedCategory = post.postType
            self.content = post.content
            self.selectedImageURLs = post.images

            if let schedule = post.schedule {
                self.hasSchedule = true
                self.scheduleTitle = schedule.title
                self.scheduleDate = schedule.date
                self.scheduleLocation = schedule.location ?? ""
                self.maxParticipants = schedule.maxParticipants
            }
        }
    }
    
    func removeImage(at index: Int) {
        guard index < selectedImageURLs.count else { return }
        let urlToRemove = selectedImageURLs[index]
        selectedImageURLs.remove(at: index)

        if urlToRemove.hasPrefix("file://") {
            ImageFileManager.shared.deleteImage(at: urlToRemove)
        } else {
            if let url = URL(string: urlToRemove) {
                KingfisherManager.shared.cache.removeImage(forKey: urlToRemove)
                KingfisherManager.shared.cache.removeImage(forKey: url.absoluteString)
            }
        }
    }
    
    func uploadPost() async -> PostResponseDTO? {
        isLoading = true
        defer { isLoading = false }

        do {
            let uploadedImageURLs = try await selectedImageUpload(selectedImageURLs: selectedImageURLs)
            let requestDTO = makeRequestDTO(uploadedImageURLs: uploadedImageURLs)

            let response = try await networkService.request(
                PostRouter.uploadPost(request: requestDTO),
                responseType: PostResponseDTO.self
            )
            return response

        } catch let error as PostUploadError {
            handleError(error, context: .postUpload)
            return nil
        } catch let error as NetworkError {
            handleError(error, context: .postUpload)
            return nil
        } catch {
            handleError(error, context: .postUpload)
            return nil
        }
    }

    func updatePost() async -> PostResponseDTO? {
        guard let postToEdit else { return nil }

        isLoading = true
        defer { isLoading = false }

        do {
            let newLocalImages = selectedImageURLs.filter { $0.hasPrefix("file://") }
            let existingRemoteImages = selectedImageURLs.filter { !$0.hasPrefix("file://") }

            let uploadedNewImages = try await selectedImageUpload(selectedImageURLs: newLocalImages)

            let allImageURLs = existingRemoteImages + uploadedNewImages

            let requestDTO = makeRequestDTO(uploadedImageURLs: allImageURLs)

            let response = try await networkService.request(
                PostRouter.updatePost(postID: postToEdit.id, request: requestDTO),
                responseType: PostResponseDTO.self
            )
            return response

        } catch let error as PostUploadError {
            handleError(error, context: .postUpload)
            return nil
        } catch let error as NetworkError {
            handleError(error, context: .postUpload)
            return nil
        } catch {
            handleError(error, context: .postUpload)
            return nil
        }
    }

    private func handleError(_ error: Error, context: ErrorContext) {
        if let networkError = error as? NetworkError {
            errorMessage = networkError.userMessage(context: context)
            errorActions = networkError.actions(context: context) { [weak self] in
                Task { @MainActor in
                    _ = await self?.uploadPost()
                }
            }
        } else if let postError = error as? PostUploadError {
            errorMessage = postError.errorDescription
            errorActions = [.confirm()]
        } else {
            errorMessage = "알 수 없는 오류가 발생했습니다."
            errorActions = [.confirm()]
        }

        showError = true

        #if DEBUG
        print("Error in \(context): \(error)")
        #endif
    }
    
    private func selectedImageUpload(selectedImageURLs: [String]) async throws -> [String] {
        guard !selectedImageURLs.isEmpty else { return [] }

        do {
            let localFileURLs = selectedImageURLs.compactMap { URL(string: $0) }

            let imageUploadRequest = ImageUploadRequestDTO(fileURLs: localFileURLs)

            let uploadResponse = try await networkService.upload(
                MultipartRouter.uploadImages(request: imageUploadRequest),
                responseType: FileUploadResponseDTO.self
            )

            let uploadedImageURLs: [String] = uploadResponse.files

            ImageFileManager.shared.deleteImages(at: selectedImageURLs)

            return uploadedImageURLs
        } catch {
            throw NetworkError.uploadFailed
        }
    }
    
    private func makeRequestDTO(uploadedImageURLs: [String]) -> PostUploadRequestDTO {
        let scheduleData: ScheduleData?
        =
        if selectedCategory == .schedule && hasSchedule {
            ScheduleData(
                title: scheduleTitle.isEmpty ? "일정" : scheduleTitle,
                date: scheduleDate,
                location: scheduleLocation.isEmpty ? nil : scheduleLocation,
                maxParticipants: maxParticipants
            )
        } else {
            nil
        }
        
        return PostMapper.toRequestDTO(
            moimId: moimId,
            postType: selectedCategory,
            content: content,
            images: uploadedImageURLs,
            schedule: scheduleData,
            location: nil
        )
    }
}
