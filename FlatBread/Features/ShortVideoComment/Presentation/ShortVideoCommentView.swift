//
//  ShortVideoCommentView.swift
//  FlatBread
//
//  Created by 김민성 on 11/26/25.
//

import SwiftUI

extension CommentReplyResponseDTO: Identifiable {
    var id: String {
        return self.commentID ?? ""
    }
}

extension CommentResponseDTO: Identifiable {
    var id: String {
        return self.commentID ?? ""
    }
}

struct ShortVideoCommentView: View {
    @StateObject var viewModel: ShortVideoCommentViewModel
    @FocusState private var isInputFocused: Bool
    
    init(videoID: String) {
        _viewModel = StateObject(wrappedValue: ShortVideoCommentViewModel(videoID: videoID))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Spacer()
                    .frame(height: 24)
                
                Text("댓글")
                    .font(.system(size: 15)).bold()
                    .padding(.bottom, 10)
                
                Divider()
            }
            .background(Color(uiColor: .systemBackground))
            
            // 댓글 리스트
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if viewModel.comments.isEmpty && !viewModel.isLoading {
                        emptyStateView
                    } else {
                        ForEach(viewModel.comments) { comment in
                            ShortVideoCommentRow(comment: comment) {
                                // 답글 달기 버튼 클릭 시
                                viewModel.setReplyTarget(comment)
                                isInputFocused = true
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding([.top, .bottom], 16)
            }
            .refreshable {
                await viewModel.fetchComments()
            }
            .scrollDismissesKeyboard(.immediately)
            
            inputBar
        }
        .background(.white)
        .task {
            await viewModel.fetchComments()
            await viewModel.updateMyProfile()
        }
        .alert("에러 발생", isPresented: $viewModel.showingAlert) {
            Button("확인", role: .cancel) { return }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Spacer().frame(height: 50)
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("아직 댓글이 없습니다.")
                .foregroundColor(.gray)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            // 답글 달기 모드일 때 표시되는 상단 바
            if let target = viewModel.replyingTo {
                HStack {
                    Text("\(target.creator?.nick ?? "사용자")님에게 답글 남기는 중")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Button {
                        viewModel.cancelReply()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(uiColor: .secondarySystemBackground))
            }
            
            HStack(alignment: .bottom, spacing: 12) {
                // TODO: 이미지 표시 안됨 - 수정 필요
                RemoteImage(
                    url: viewModel.myProfile?.profileImage ?? "",
                    displayMode: .thumbnail(.init(width: 32, height: 32)),
                    content: { image in
                        return image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .foregroundStyle(.gray)
                    }
                )
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                
                // 텍스트 필드
                HStack {
                    TextField(viewModel.replyingTo != nil ? "답글 추가..." : "댓글 추가...", text: $viewModel.inputText, axis: .vertical)
                        .focused($isInputFocused)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                // 전송 버튼
                if !viewModel.inputText.isEmpty {
                    Button {
                        Task {
                            await viewModel.sendComment()
                            isInputFocused = false
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(Color.juhwang)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
}

#Preview {
    ShortVideoCommentView(videoID: "a")
}
