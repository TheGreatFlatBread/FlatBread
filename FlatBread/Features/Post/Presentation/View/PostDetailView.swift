//
//  PostDetailView.swift
//  FlatBread
//
//  Created by hwan on 11/19/25.
//

import SwiftUI

struct PostDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var commentViewModel: CommentViewModel
    @EnvironmentObject private var postListViewModel: PostListViewModel
    
    @FocusState private var isFocused: Bool
    @State private var showPostOptions = false
    @State private var showDeletePostConfirmation = false
    @State private var showEditSheet = false
    @State private var isDeletingPost = false
    
    
    var post: PostUIModel? {
        postListViewModel.posts.first(where: { $0.id == postId })
    }
    let postId: String
    let currentUserId: String
    
    init(postId: String, currentUserId: String) {
        self.postId = postId
        self.currentUserId = currentUserId
        _commentViewModel = StateObject(
            wrappedValue: CommentViewModel(
                postId: postId,
                currentUserId: currentUserId
            )
        )
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    PostDetailView.PostDetailCard(
                        post: post,
                        commentCount: commentViewModel.comments.count
                    )

                    Divider()
                        .padding(.vertical, 16)

                    PostDetailView.CommentHeader(commentCount: commentViewModel.comments.count)

                    if commentViewModel.comments.isEmpty && !commentViewModel.isLoading {
                        PostDetailView.EmptyCommentView()
                    } else {
                        PostDetailView.CommentList(
                            comments: commentViewModel.comments,
                            viewModel: commentViewModel,
                            onReply: { comment in
                                commentViewModel.startReply(to: comment)
                                isFocused = true
                            }
                        )
                    }
                }
                .padding(.bottom, 80)
            }

            PostDetailView.CommentInputField(
                commentText: $commentViewModel.commentText,
                isFocused: $isFocused,
                canPost: commentViewModel.canPost,
                isLoading: commentViewModel.isLoading,
                replyingTo: commentViewModel.replyingTo,
                onSend: {
                    isFocused = false
                    Task {
                        let success = await self.commentViewModel.writeComment {
                            postListViewModel.incrementCommentCount(for: self.postId)
                        }
                        if success {
                            commentViewModel.commentText = ""
                            commentViewModel.cancelReply()
                        }
                    }
                },
                onCancelReply: {
                    isFocused = false
                    commentViewModel.cancelReply()
                }
            )
        }
        .toolbarRole(.editor)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarItems
        }
        .task {
            await commentViewModel.loadComments()
        }
        .alert("오류", isPresented: $commentViewModel.showError) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(commentViewModel.errorMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
        .confirmationDialog("게시물 옵션", isPresented: $showPostOptions) {
            if let post, post.author.id == currentUserId {
                Button("수정") {
                    showEditSheet = true
                }
                Button("삭제", role: .destructive) {
                    showDeletePostConfirmation = true
                }
            } else {
                // TODO: 신고 기능
                // Button("신고", role: .destructive) { }
            }
        }
        .alert("게시물을 삭제하시겠습니까?", isPresented: $showDeletePostConfirmation) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                Task {
                    await deletePost()
                }
            }
        }
        .fullScreenCover(isPresented: $showEditSheet) {
            if let post {
                PostPatchView(
                    post: post,
                    onPostUpdated: { response in
                        postListViewModel.updateExistingPost(response)
                    }
                )
            }
        }
        .onChange(of: showEditSheet) { oldValue, newValue in
            if !newValue {
                Task {
                    await commentViewModel.loadComments()
                }
            }
        }
        .overlay {
            if isDeletingPost {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        }
    }

    @MainActor
    private func deletePost() async {
        isDeletingPost = true
        let success = await postListViewModel.deletePost(self.postId)
        isDeletingPost = false
        if success {
            dismiss()
        }
    }

    @ToolbarContentBuilder
    var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("게시물")
                .font(.system(size: 17, weight: .semibold))
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showPostOptions = true
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
            }
        }
    }
}

extension PostDetailView {
    struct PostDetailCard: View {
        let post: PostUIModel?
        let commentCount: Int

        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                if let post {
                    PostDetailView.AuthorHeader(
                        authorName: post.author.name,
                        createdAt: post.createdAt
                    )

                    Text(post.content)
                        .font(.system(size: 16))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    if !post.images.isEmpty {
                        PostDetailView.ImageGallery(images: post.images)
                    }

                    if !post.hashtags.isEmpty {
                        PostDetailView.HashtagView(hashtags: post.hashtags)
                    }

                    PostDetailView.PostStats(
                        isLiked: post.isLiked,
                        likeCount: post.likeCount,
                        commentCount: commentCount
                    )
                } else {
                    Color.clear
                }
            }
            .padding(16)
        }
    }

    struct AuthorHeader: View {
        let authorName: String
        let createdAt: Date

        var body: some View {
            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay {
                        Text(String(authorName.prefix(1)))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.orange)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(authorName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(createdAt.relativeTimeString())
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }

    struct ImageGallery: View {
        let images: [String]
        @State private var currentIndex = 0

        var body: some View {
            ZStack(alignment: .bottom) {
                TabView(selection: $currentIndex) {
                    ForEach(Array(images.enumerated()), id: \.element) { index, imageURL in
                        RemoteImage(
                            url: imageURL,
                            displayMode: .thumbnail(CGSize(width: 400, height: 400))
                        ) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 400)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .tag(index)
                    }
                }
                .frame(height: 400)
                .tabViewStyle(.page(indexDisplayMode: .never))

                if images.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<images.count, id: \.self) { index in
                            Circle()
                                .fill(currentIndex == index ? Color.white : Color.white.opacity(0.5))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Capsule())
                    .padding(.bottom, 16)
                }
            }
        }
    }

    struct HashtagView: View {
        let hashtags: [String]

        var body: some View {
            FlowLayout(spacing: 8) {
                ForEach(hashtags, id: \.self) { hashtag in
                    Text("#\(hashtag)")
                        .font(.system(size: 14))
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    struct PostStats: View {
        let isLiked: Bool
        let likeCount: Int
        let commentCount: Int

        var body: some View {
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(isLiked ? .red : .secondary)
                    Text("\(likeCount)")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 6) {
                    Image(systemName: "bubble.right")
                        .foregroundStyle(.secondary)
                    Text("\(commentCount)")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .font(.system(size: 16))
        }
    }

    struct CommentHeader: View {
        let commentCount: Int

        var body: some View {
            HStack {
                Text("댓글")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("\(commentCount)")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    struct EmptyCommentView: View {
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary.opacity(0.3))
                Text("첫 댓글을 남겨보세요")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
    }

    struct CommentList: View {
        let comments: [CommentUIModel]
        @ObservedObject var viewModel: CommentViewModel
        let onReply: (CommentUIModel) -> Void

        var body: some View {
            LazyVStack(spacing: 0) {
                ForEach(comments, id: \.id) { comment in
                    CommentCell(
                        comment: comment,
                        isMyComment: viewModel.isMyComment(comment),
                        isMyReply: { reply in
                            viewModel.isMyComment(reply)
                        },
                        onReply: {
                            onReply(comment)
                        },
                        onDelete: {
                            Task {
                                await viewModel.deleteComment(commentId: comment.id)
                            }
                        },
                        onDeleteReply: { replyId in
                            Task {
                                await viewModel.deleteComment(commentId: replyId)
                            }
                        },
                        onUpdate: { newContent in
                            Task {
                                await viewModel.updateComment(commentId: comment.id, newContent: newContent)
                            }
                        },
                        onUpdateReply: { replyId, newContent in
                            Task {
                                await viewModel.updateComment(commentId: replyId, newContent: newContent)
                            }
                        }
                    )
                    Divider()
                        .padding(.leading, 60)
                }
            }
        }
    }

    struct CommentInputField: View {
        @Binding var commentText: String
        @FocusState.Binding var isFocused: Bool
        let canPost: Bool
        let isLoading: Bool
        let replyingTo: CommentUIModel?
        let onSend: () -> Void
        let onCancelReply: () -> Void

        var body: some View {
            VStack(spacing: 0) {
                Divider()

                if let replyingTo {
                    HStack {
                        Text("답글: @\(replyingTo.authorName)")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            onCancelReply()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                }

                HStack(spacing: 12) {
                    TextField("댓글을 입력하세요...", text: $commentText, axis: .vertical)
                        .focused($isFocused)
                        .lineLimit(1...5)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Button {
                        onSend()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(canPost ? Color.orange : Color.gray.opacity(0.3))
                    }
                    .disabled(!canPost || isLoading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeRows(proposal: proposal, subviews: subviews)
        let totalHeight = result.reduce(CGFloat(0)) { partialResult, row in
            partialResult + row.height
        }
        let spacingHeight = CGFloat(max(0, result.count - 1)) * spacing
        return CGSize(width: proposal.width ?? 0, height: totalHeight + spacingHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeRows(proposal: proposal, subviews: subviews)
        var yPosition: CGFloat = bounds.minY

        for row in rows {
            var xPosition: CGFloat = bounds.minX

            for subviewIndex in row.indices {
                let viewSize: CGSize = subviews[subviewIndex].sizeThatFits(.unspecified)
                let position = CGPoint(x: xPosition, y: yPosition)
                subviews[subviewIndex].place(at: position, proposal: .unspecified)
                xPosition += viewSize.width + spacing
            }

            yPosition += row.height + spacing
        }
    }

    private func arrangeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow: [Int] = []
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0

        let maxWidth: CGFloat = proposal.width ?? .infinity

        for (index, subview) in subviews.enumerated() {
            let viewSize: CGSize = subview.sizeThatFits(.unspecified)
            let viewWidth: CGFloat = viewSize.width
            let viewHeight: CGFloat = viewSize.height

            let needsNewRow = currentRowWidth + viewWidth > maxWidth && !currentRow.isEmpty

            if needsNewRow {
                rows.append(Row(indices: currentRow, height: currentRowHeight))
                currentRow = [index]
                currentRowWidth = viewWidth
                currentRowHeight = viewHeight
            } else {
                currentRow.append(index)
                currentRowWidth += viewWidth
                if !currentRow.isEmpty {
                    currentRowWidth += spacing
                }
                currentRowHeight = max(currentRowHeight, viewHeight)
            }
        }

        if !currentRow.isEmpty {
            rows.append(Row(indices: currentRow, height: currentRowHeight))
        }

        return rows
    }

    struct Row {
        var indices: [Int]
        var height: CGFloat
    }
}

#Preview {
    // PostDetailView(post: PostUIModel.mocks[0])
}
