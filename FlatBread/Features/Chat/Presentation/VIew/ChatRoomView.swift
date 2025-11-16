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
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    init(room: ChatRoomModel, currentUserID: String) {
        _viewModel = StateObject(
            wrappedValue: ChatRoomViewModel(room: room, currentUserID: currentUserID)
        )
    }

    init(viewModel: ChatRoomViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            RefreshableContainer(
                reverse: true,
                content: {
                    ChatSectionConatiner(
                        chatSection: self.viewModel.groupedMessages,
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
        .navigationTitle(viewModel.room.participants.first?.nick ?? "채팅방")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("사진 선택", isPresented: $showImageSourcePicker) {
            Button("카메라") {
                showCamera = true
            }
            Button("보관함") {
                showPhotoPicker = true
            }
            Button("취소", role: .cancel) {}
        }
        .sheet(isPresented: $showCamera) {
            CameraImagePicker { image in
                Task {
                    let url = ImageFileManager.shared.saveImage(image)
                    await MainActor.run {
                        if let url {
                            viewModel.selectedImageURLs.append(url)
                        }
                    }
                }
fileprivate struct ChatSectionConatiner: View {
    let chatSection: [ChatMessageSection]
    let currentUserID: String
    let retry: (ChatMessageModel) -> Void
    
    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(chatSection, id: \.id) { section in
                ChatListComponent(
                    date: section.date,
                    displayConfigs: section.displayConfigs,
                    currentUserID: currentUserID,
                    retry: retry
                )
            }
        }
        .padding(.vertical, 8)
    }
}

fileprivate struct ChatListComponent: View {
    let date: String
    let displayConfigs: [MessageDisplayConfig]
    let currentUserID: String
    let retry: (ChatMessageModel) -> Void
    
    var body: some View {
        Text(self.date)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.gray)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(uiColor: .systemGray6))
            .cornerRadius(12)
            .padding(.vertical, 8)
        
        ForEach(self.displayConfigs, id: \.id) { config in
            ChatBubbleCell(
                config: config,
                isMyMessage: config.message.sender.id == currentUserID,
                onRetry: { message in
                    retry(message)
                }
            )
        }
    }
}
