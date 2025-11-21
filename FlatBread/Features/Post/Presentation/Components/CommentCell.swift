//
//  CommentCell.swift
//  FlatBread
//
//  Created by hwan on 11/19/25.
//

import SwiftUI

struct CommentCell: View {
    let comment: CommentUIModel
    let isMyComment: Bool
    let isMyReply: (CommentUIModel) -> Bool
    let onReply: () -> Void
    let onDelete: () -> Void
    let onDeleteReply: (String) -> Void
    let onUpdate: (String) -> Void
    let onUpdateReply: (String, String) -> Void

    @State private var isExpanded = false
    @State private var showCommentOptions = false
    @State private var showDeleteReplyConfirmation = false
    @State private var replyToDelete: CommentUIModel?
    @State private var isEditingComment = false
    @State private var editingCommentText = ""
    @State private var editingReplyId: String?
    @State private var editingReplyText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            commentContent

            if isExpanded {
                repliesList
            }
        }
        .contentShape(Rectangle())
        .confirmationDialog("댓글 옵션", isPresented: $showCommentOptions) {
            Button("수정") {
                editingCommentText = comment.content
                isEditingComment = true
            }
            Button("삭제", role: .destructive) {
                onDelete()
            }
        }
        .confirmationDialog("답글 옵션", isPresented: $showDeleteReplyConfirmation, presenting: replyToDelete) { reply in
            Button("수정") {
                editingReplyId = reply.id
                editingReplyText = reply.content
                showDeleteReplyConfirmation = false
                replyToDelete = nil
            }
            Button("삭제", role: .destructive) {
                onDeleteReply(reply.id)
                replyToDelete = nil
            }
        }
    }

    private var commentContent: some View {
        HStack(alignment: .top, spacing: 12) {
            PostProfileImage(
                profileImageURL: comment.profileImageURL,
                name: comment.authorName,
                size: 36
            )

            VStack(alignment: .leading, spacing: 6) {
                commentHeader

                if isEditingComment {
                    CommentEditView(
                        text: $editingCommentText,
                        placeholder: "댓글을 입력하세요",
                        fontSize: 15,
                        onCancel: {
                            isEditingComment = false
                            editingCommentText = ""
                        },
                        onSave: {
                            onUpdate(editingCommentText)
                            isEditingComment = false
                            editingCommentText = ""
                        }
                    )
                } else {
                    commentBody
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var commentHeader: some View {
        HStack(spacing: 6) {
            Text(comment.authorName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)

            Text(comment.createdAt.relativeTimeString())
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Spacer()

            if isMyComment {
                Button {
                    showCommentOptions = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var commentBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(comment.content)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button {
                    onReply()
                } label: {
                    Text("답글")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                if comment.replyCount > 0 {
                    Button {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("답글 \(comment.replyCount)개")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var repliesList: some View {
        VStack(spacing: 0) {
            ForEach(comment.replies, id: \.id) { reply in
                ReplyCell(
                    reply: reply,
                    isMyReply: isMyReply(reply),
                    isEditing: editingReplyId == reply.id,
                    editingText: $editingReplyText,
                    onEdit: {
                        replyToDelete = reply
                        showDeleteReplyConfirmation = true
                    },
                    onCancelEdit: {
                        editingReplyId = nil
                        editingReplyText = ""
                    },
                    onSaveEdit: {
                        onUpdateReply(reply.id, editingReplyText)
                        editingReplyId = nil
                        editingReplyText = ""
                    }
                )
            }
        }
    }
}

struct ReplyCell: View {
    let reply: CommentUIModel
    let isMyReply: Bool
    let isEditing: Bool
    @Binding var editingText: String
    let onEdit: () -> Void
    let onCancelEdit: () -> Void
    let onSaveEdit: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Spacer()
                .frame(width: 48)

            PostProfileImage(
                profileImageURL: reply.profileImageURL,
                name: reply.authorName,
                size: 32
            )

            VStack(alignment: .leading, spacing: 4) {
                replyHeader

                if isEditing {
                    CommentEditView(
                        text: $editingText,
                        placeholder: "답글을 입력하세요",
                        fontSize: 14,
                        onCancel: onCancelEdit,
                        onSave: onSaveEdit
                    )
                } else {
                    Text(reply.content)
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemGray6).opacity(0.3))
    }

    private var replyHeader: some View {
        HStack(spacing: 6) {
            Text(reply.authorName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            Text(reply.createdAt.relativeTimeString())
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Spacer()

            if isMyReply {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct CommentEditView: View {
    @Binding var text: String
    let placeholder: String
    let fontSize: CGFloat
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            TextField(placeholder, text: $text, axis: .vertical)
                .font(.system(size: fontSize))
                .lineLimit(1...10)
                .textFieldStyle(.plain)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)

            HStack(spacing: 8) {
                Button("취소") {
                    onCancel()
                }
                .font(.system(size: fontSize - 2, weight: .medium))
                .foregroundStyle(.secondary)

                Spacer()

                Button("저장") {
                    onSave()
                }
                .font(.system(size: fontSize - 2, weight: .semibold))
                .foregroundStyle(.orange)
            }
        }
    }
}
