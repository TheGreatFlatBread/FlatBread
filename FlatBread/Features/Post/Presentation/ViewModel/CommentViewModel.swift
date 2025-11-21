//
//  CommentViewModel.swift
//  FlatBread
//
//  Created by hwan on 11/19/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class CommentViewModel: ObservableObject {
    @Published var comments: [CommentUIModel] = []
    @Published var commentText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var replyingTo: CommentUIModel?

    private let networkService: AsyncNetworkService
    private let postId: String
    private let currentUserId: String
    
    var canPost: Bool {
        !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func startReply(to comment: CommentUIModel) {
        replyingTo = comment
    }

    func cancelReply() {
        replyingTo = nil
        commentText = ""
    }

    init(postId: String, currentUserId: String) {
        self.postId = postId
        self.currentUserId = currentUserId
        self.networkService = NetworkServiceFactory.shared.makeNetworkService()
    }

    func loadComments() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await networkService.request(
                CommentRouter.getCommentList(postID: postId),
                responseType: CommentListResponseDTO.self
            )

            comments = response.data.compactMap { dto in
                CommentMapper.toUIModel(from: dto)
            }
        } catch {
            handleError(error, context: .postFetch)
        }
    }

    func writeComment(onCommentAdded: (() -> Void)? = nil) async -> Bool {
        guard canPost else { return false }

        isLoading = true
        defer { isLoading = false }

        do {
            if let parentComment = replyingTo {
                _ = try await networkService.request(
                    CommentRouter.writeSubComment(
                        postID: postId,
                        commentID: parentComment.id,
                        content: commentText
                    ),
                    responseType: CommentWriteResponseDTO.self
                )
            } else {
                _ = try await networkService.request(
                    CommentRouter.writeComment(postID: postId, content: commentText),
                    responseType: CommentWriteResponseDTO.self
                )
            }
            await loadComments()
            commentText = ""
            onCommentAdded?()
            return true
        } catch {
            handleError(error, context: .postUpload)
            return false
        }
    }

    func updateComment(commentId: String, newContent: String) async -> Bool {
        guard !newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        // 낙관적 업데이트: 기존 내용 백업 후 즉시 변경
        let oldContent = updateCommentLocally(commentId: commentId, newContent: newContent)

        do {
            _ = try await networkService.request(
                CommentRouter.updateComment(postID: postId, commentID: commentId, content: newContent),
                responseType: EmptyEntity.self
            )
            return true
        } catch {
            // 실패 시 원래 내용으로 복원
            if let oldContent = oldContent {
                _ = updateCommentLocally(commentId: commentId, newContent: oldContent)
            }
            handleError(error, context: .postFetch)
            return false
        }
    }

    private func updateCommentLocally(commentId: String, newContent: String) -> String? {
        for index in comments.indices {
            if comments[index].id == commentId {
                let oldContent = comments[index].content
                comments[index].content = newContent
                return oldContent
            }
            if let replyIndex = comments[index].replies.firstIndex(where: { $0.id == commentId }) {
                let oldContent = comments[index].replies[replyIndex].content
                comments[index].replies[replyIndex].content = newContent
                return oldContent
            }
        }
        return nil
    }

    func deleteComment(commentId: String) async -> Bool {
        let backup = deleteCommentLocally(commentId: commentId)

        do {
            _ = try await networkService.request(
                CommentRouter.deleteComment(postID: postId, commentID: commentId),
                responseType: EmptyEntity.self
            )
            return true
        } catch {
            restoreComment(backup)
            handleError(error, context: .postFetch)
            return false
        }
    }

    private func deleteCommentLocally(commentId: String) -> CommentBackup? {
        if let index = comments.firstIndex(where: { $0.id == commentId }) {
            let deletedComment = comments[index]
            comments.remove(at: index)
            return .comment(index: index, comment: deletedComment)
        }

        for commentIndex in comments.indices {
            if let replyIndex = comments[commentIndex].replies.firstIndex(where: { $0.id == commentId }) {
                let deletedReply = comments[commentIndex].replies[replyIndex]
                comments[commentIndex].replies.remove(at: replyIndex)
                return .reply(commentIndex: commentIndex, replyIndex: replyIndex, reply: deletedReply)
            }
        }

        return nil
    }

    private func restoreComment(_ backup: CommentBackup?) {
        guard let backup else { return }

        switch backup {
        case .comment(let index, let comment):
            if index <= comments.count {
                comments.insert(comment, at: index)
            }
        case .reply(let commentIndex, let replyIndex, let reply):
            if commentIndex < comments.count, replyIndex <= comments[commentIndex].replies.count {
                comments[commentIndex].replies.insert(reply, at: replyIndex)
            }
        }
    }

    private enum CommentBackup {
        case comment(index: Int, comment: CommentUIModel)
        case reply(commentIndex: Int, replyIndex: Int, reply: CommentUIModel)
    }

    func isMyComment(_ comment: CommentUIModel) -> Bool {
        return comment.authorId == currentUserId
    }

    private func handleError(_ error: NetworkError, context: ErrorContext) {
        errorMessage = error.userMessage(context: context)
        showError = true

        #if DEBUG
        print("❌ Error in \(context): \(error)")
        #endif
    }
}
