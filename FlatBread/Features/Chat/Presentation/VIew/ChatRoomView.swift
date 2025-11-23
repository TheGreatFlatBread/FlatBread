//
//  ChatRoomView.swift
//  FlatBread
//
//  Created by hwan on 11/12/25.
//

import SwiftUI
import PhotosUI

struct ChatRoomView: View {
    @StateObject private var viewModel: ChatRoomViewModel
    @FocusState private var isTextFieldFocused: Bool
    @State private var showImageSourcePicker = false

    /// 기존 채팅방으로 진입
    init(room: ChatRoomModel, currentUserID: String) {
        _viewModel = StateObject(
            wrappedValue: ChatRoomViewModel(room: room, currentUserID: currentUserID)
        )
    }

    /// 새 채팅 시작 (opponent 정보로 진입, 첫 메시지 전송 시 room 생성)
    init(opponentID: String, opponentNick: String, opponentProfileImage: String?, currentUserID: String) {
        _viewModel = StateObject(
            wrappedValue: ChatRoomViewModel(
                opponentID: opponentID,
                opponentNick: opponentNick,
                opponentProfileImage: opponentProfileImage,
                currentUserID: currentUserID
            )
        )
    }

    init(viewModel: ChatRoomViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isEmpty {
                emptyChatPlaceholder
            } else {
                RefreshableContainer(
                    reverse: true,
                    content: {
                        ChatItemsContainer(
                            chatItems: self.viewModel.chatItems,
                            currentUserID: self.viewModel.currentUserID,
                            retry: self.viewModel.retryMessage(_:)
                        )
                    },
                    onRefresh: {
                        Task {
                            await viewModel.loadMoreMessages()
                        }
                    },
                    scrollPosition: $viewModel.scrollPosition
                )
                .scrollDismissesKeyboard(.interactively)
            }

            MessageInputField(
                text: $viewModel.messageText,
                selectedImageURLs: $viewModel.selectedImageURLs,
                isFocused: $isTextFieldFocused,
                onSend: { viewModel.sendMessage() },
                onRemoveImage: { index in viewModel.removeImage(at: index) },
                onCameraButtonTap: { showImageSourcePicker = true },
                onImageButtonTap: { showImageSourcePicker = true },
                onVoiceButtonTap: { /* print("Voice tapped") */ },
                onEmojiButtonTap: { /* print("Emoji tapped") */},
                onPlusButtonTap: { /* print("Plus tapped") */ }
            )
        }
        .navigationTitle(viewModel.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .imagePicker(
            selectedImageURLs: $viewModel.selectedImageURLs,
            showPicker: $showImageSourcePicker
        )
        .overlay {
            if viewModel.isCreatingRoom {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView("채팅방 생성 중...")
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
            }
        }
        .task {
            await viewModel.fetchChatMessageList()
        }
    }

    private var emptyChatPlaceholder: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("새로운 채팅을 시작해보세요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

fileprivate struct ChatItemsContainer: View {
    let chatItems: [ChatItem]
    let currentUserID: String
    let retry: (ChatMessageModel) -> Void

    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(chatItems) { item in
                switch item {
                case .dateHeader(_, let dateFormatted):
                    ChatDateHeader(dateFormatted: dateFormatted)
                case .message(let config):
                    ChatBubbleCell(
                        config: config,
                        isMyMessage: config.message.sender.id == currentUserID,
                        onRetry: { message in retry(message) }
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }
}

fileprivate struct ChatDateHeader: View {
    let dateFormatted: String

    var body: some View {
        Text(dateFormatted)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.gray)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(uiColor: .systemGray6))
            .cornerRadius(12)
            .padding(.vertical, 8)
    }
}
