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
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.groupedMessages, id: \.id) { section in
                            Text(section.dateFormatted)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color(uiColor: .systemGray6))
                                .cornerRadius(12)
                                .padding(.vertical, 8)
                            
                            ForEach(section.displayConfigs, id: \.id) { config in
                                ChatBubbleCell(
                                    config: config,
                                    isMyMessage: config.message.sender.id == viewModel.currentUserID,
                                    onRetry: { message in
                                        viewModel.retryMessage(message)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.vertical, 8)
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
                onSend: {
                    viewModel.sendMessage()
                },
                onRemoveImage: { index in
                    viewModel.removeImage(at: index)
                },
                onCameraButtonTap: {
                    showImageSourcePicker = true
                },
                onImageButtonTap: {
                    showImageSourcePicker = true
                },
                onVoiceButtonTap: {
                    print("Voice tapped")
                },
                onEmojiButtonTap: {
                    print("Emoji tapped")
                },
                onPlusButtonTap: {
                    print("Plus tapped")
                }
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
            }
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotoItems,
            maxSelectionCount: 5,
            matching: .images
        )
        .onChange(of: selectedPhotoItems) { oldItems, newItems in
            Task { @concurrent in
                var imageDatas: [Data] = []
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        imageDatas.append(data)
                    }
                }
                let savedURLs = await ImageFileManager.shared.saveImagesData(imageDatas)
                await MainActor.run {
                    selectedPhotoItems.removeAll()
                    viewModel.selectedImageURLs.append(contentsOf: savedURLs)
                }
            }
        }
    }
}
