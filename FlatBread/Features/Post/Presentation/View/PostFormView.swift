//
//  PostFormView.swift
//  FlatBread
//
//  Created by hwan on 11/20/25.
//

import SwiftUI

struct PostWriteView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PostWriteViewModel

    let onPostCreated: ((PostResponseDTO) -> Void)?

    init(
        moimId: String,
        onPostCreated: ((PostResponseDTO) -> Void)? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: PostWriteViewModel(
                moimId: moimId,
                postToEdit: nil,
                imageService: ImageServiceKey.defaultValue
            )g
        )
        self.onPostCreated = onPostCreated
    }

    var body: some View {
        PostFormView(
            viewModel: viewModel,
            title: "새 게시글",
            buttonText: "게시",
            onSubmit: {
                if let response = await viewModel.uploadPost() {
                    onPostCreated?(response)
                    dismiss()
                }
            }
        )
    }
}

struct PostPatchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PostWriteViewModel

    let onPostUpdated: ((PostResponseDTO) -> Void)?

    init(
        post: PostUIModel,
        onPostUpdated: ((PostResponseDTO) -> Void)? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: PostWriteViewModel(
                moimId: post.moimId,
                postToEdit: post,
                imageService: ImageServiceKey.defaultValue
            )
        )
        self.onPostUpdated = onPostUpdated
    }

    var body: some View {
        PostFormView(
            viewModel: viewModel,
            title: "게시글 수정",
            buttonText: "수정",
            onSubmit: { @MainActor in
                if let response = await viewModel.updatePost() {
                    onPostUpdated?(response)
                    dismiss()
                }
            }
        )
    }
}

private struct PostFormView: View {
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: PostWriteViewModel
    @State private var showImagePicker = false
    @State private var showSchedulePicker = false

    let title: String
    let buttonText: String
    let onSubmit: @MainActor () async -> Void

    private var imageSubTitle: String {
        viewModel.selectedImageURLs.isEmpty ? "최대 5장" : "\(viewModel.selectedImageURLs.count)장 선택됨"
    }

    private var scheduleSubTitle: String {
        viewModel.hasSchedule ? viewModel.scheduleDate.formatted(date: .abbreviated, time: .shortened) : "일정과 함께 게시"
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    PostFormComponents.CategoryPicker(selectedCategory: $viewModel.selectedCategory)

                    PostFormComponents.ContentEditor(content: $viewModel.content)

                    VStack(spacing: 12) {
                        PostFormComponents.Attachment(
                            icon: "photo.on.rectangle",
                            title: "사진 추가",
                            subTitle: imageSubTitle,
                            isActive: !viewModel.selectedImageURLs.isEmpty
                        ) {
                            showImagePicker = true
                        }

                        if !viewModel.selectedImageURLs.isEmpty {
                            PostFormComponents.ImagePreviewGrid(
                                imageURLs: viewModel.selectedImageURLs,
                                onDelete: { index in
                                    viewModel.removeImage(at: index)
                                }
                            )
                        }

                        if viewModel.selectedCategory == .schedule {
                            PostFormComponents.Attachment(
                                icon: "calendar.badge.plus",
                                title: "일정 추가",
                                subTitle: scheduleSubTitle,
                                isActive: viewModel.hasSchedule
                            ) {
                                showSchedulePicker = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
            }
            .background(Color(.systemBackground))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolBarItems
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .imagePicker(selectedImageURLs: $viewModel.selectedImageURLs, showPicker: $showImagePicker)
        .sheet(isPresented: $showSchedulePicker) {
            SchedulePicker(
                scheduleDate: $viewModel.scheduleDate,
                scheduleTitle: $viewModel.scheduleTitle,
                scheduleLocation: $viewModel.scheduleLocation,
                maxParticipants: $viewModel.maxParticipants,
                showSchedulePicker: $showSchedulePicker,
                hasSchedule: $viewModel.hasSchedule
            )
        }
        .alert("오류", isPresented: $viewModel.showError) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
        .overlay {
            if viewModel.isLoading {
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

    @ToolbarContentBuilder
    var toolBarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Task {
                    await onSubmit()
                }
            } label: {
                Text(buttonText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: viewModel.canPost ? [Color.orange, Color.orange.opacity(0.85)] : [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
            .disabled(!viewModel.canPost || viewModel.isLoading)
        }
    }
}

#Preview("Write") {
    PostWriteView(moimId: "test-moim-id")
}

#Preview("Patch") {
    PostPatchView(post: PostUIModel.mocks[0])
}
