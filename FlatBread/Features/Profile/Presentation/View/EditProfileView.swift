//
//  EditProfileView.swift
//  FlatBread
//
//  Created by 김민성 on 11/13/25.
//

import SwiftUI
import PhotosUI

private struct ProfileAvatarView: View {
    let previewData: Data?
    let remoteURLString: String?
    var body: some View {
        Group {
            if let data = previewData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let urlString = remoteURLString, !urlString.isEmpty {
                RemoteImage(url: urlString, displayMode: .thumbnail(CGSize(width: 120, height: 120))) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFill()
                } content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.secondary, lineWidth: 1))
        .contentShape(Circle())
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditProfileViewModel
    @State private var selectedItem: PhotosPickerItem?
    @FocusState private var focusedField: Field?
    var onSuccess: (() -> Void)?

    enum Field {
        case nickname, phone, birth
    }

    init(userProfile: UserProfileResponseDTO, onSuccess: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: EditProfileViewModel(existingProfile: userProfile))
        self.onSuccess = onSuccess
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            ProfileAvatarView(previewData: viewModel.previewImageData, remoteURLString: viewModel.existingProfile.profileImage)
                                .overlay(
                                    ZStack {
                                        if viewModel.isProcessingImage {
                                            Circle()
                                                .fill(Color.black.opacity(0.05))
                                            ProgressView()
                                        }
                                    }
                                )
                            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                                Text("사진 선택")
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    if !viewModel.isImageValid {
                        Text("유효한 프로필 이미지를 선택해주세요.")
                            .foregroundColor(.red)
                            .font(.footnote)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }

                Section("닉네임") {
                    TextField("닉네임을 입력하세요", text: $viewModel.nickname)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: .nickname)
                }

                Section("전화번호") {
                    TextField("전화번호를 입력하세요", text: $viewModel.phone)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .phone)
                }

                Section("생년월일") {
                    DatePicker("생년월일 선택", selection: $viewModel.birth, displayedComponents: .date)
                        .focused($focusedField, equals: .birth)
                }

                Section("성별") {
                    Picker("성별 선택", selection: $viewModel.gender) {
                        ForEach(EditProfileViewModel.GenderOption.allCases, id: \.self) { gender in
                            Text(gender.description).tag(gender)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if viewModel.isUploading {
                    Section {
                        HStack(spacing: 8) {
                            ProgressView(value: viewModel.uploadProgress)
                            Text("업로드 중…")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Button {
                        Task {
                            await viewModel.submit()
                            if !viewModel.isUploading && viewModel.errorMessage == nil {
                                onSuccess?()
                                dismiss()
                            }
                        }
                    } label: {
                        Text(viewModel.isUploading ? "" : "저장")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .overlay(
                                Group { if viewModel.isUploading { HStack { Spacer(); ProgressView(); Spacer() } } }
                            )
                            .frame(height: 44)
                            .background((viewModel.canSubmit && !viewModel.isUploading) ? Color("juhwang") : Color(.systemGray5))
                            .foregroundStyle((viewModel.canSubmit && !viewModel.isUploading) ? .white : .secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(!viewModel.canSubmit || viewModel.isUploading)
                }
            }
            .navigationTitle("프로필 수정")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture { focusedField = nil }
            .onChange(of: selectedItem) { _, newItem in
                guard let item = newItem else { viewModel.setProfileImage(data: nil); return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        await MainActor.run { viewModel.setProfileImage(data: data) }
                    }
                }
            }
            .alert("오류", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "알 수 없는 오류")
            }
        }
    }
}

#Preview {
    EditProfileView(userProfile: UserProfileResponseDTO.profileViewDummy)
}
