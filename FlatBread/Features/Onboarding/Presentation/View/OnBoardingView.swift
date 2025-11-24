//
//  OnBoardingView.swift
//  FlatBread
//
//  Created by andev on 11/23/25.
//

import SwiftUI
import PhotosUI

struct OnBoardingView: View {
    @StateObject private var vm = OnBoardingViewModel()
    @State private var pickerItem: PhotosPickerItem? = nil
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccessAlert: Bool = false

    enum Field { case nick, phone, birth }

    // Computed helpers
    private static let birthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private var formattedBirthDate: String {
        Self.birthFormatter.string(from: vm.birthDate)
    }

    private var isNickValid: Bool {
        vm.validateNick(vm.nick)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("프로필을 완성해요")
                    .font(.system(size: 28, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            if vm.shouldShowOnboarding {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // MARK: - 대표 사진
                        ProfileImageSection(vm: vm, pickerItem: $pickerItem)
                            .padding(.horizontal, 16)

                        // MARK: - 닉네임
                        NicknameSection(vm: vm, focusedField: _focusedField)
                            .padding(.horizontal, 16)

                        // MARK: - 연락처
                        PhoneSection(vm: vm, focusedField: _focusedField)
                            .padding(.horizontal, 16)

                        // MARK: - 생년월일
                        BirthSection(vm: vm, formattedBirthDate: .constant(formattedBirthDate), focusedField: _focusedField)
                            .padding(.horizontal, 16)

                        // MARK: - 성별
                        GenderSection(vm: vm)
                            .padding(.horizontal, 16)

                        Spacer(minLength: 24)
                    }
                    .padding(.vertical, 12)
                }

                if vm.isUploading {
                    HStack(spacing: 8) {
                        ProgressView(value: vm.uploadProgress)
                        Text("업로드 중…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                }

                Button {
                    Task {
                        let success = await vm.submit()
                        if success {
                            showSuccessAlert = true
                        }
                    }
                } label: {
                    Text("완료")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(vm.canSubmit ? Color.black : Color(.systemGray5))
                        .foregroundStyle(vm.canSubmit ? .white : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .disabled(!vm.canSubmit)
                .background(Color(.systemBackground))

                if !vm.canSubmit {
                    if !isNickValid {
                        Text("닉네임 형식이 올바르지 않습니다.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.bottom, 8)
                            .padding(.horizontal, 16)
                    } else if vm.profileImageData != nil && !vm.isImageValid {
                        Text("이미지 용량이 너무 큽니다. 200KB 이하 파일을 선택해 주세요.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.bottom, 8)
                            .padding(.horizontal, 16)
                    }
                }
            } else {
                // Onboarding not needed, route to Home here
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onTapGesture { focusedField = nil }
        .background(Color(.systemBackground))
        .alert("프로필 업데이트 실패", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "오류가 발생했습니다. 다시 시도해 주세요.")
        }
        .alert("프로필 설정 완료", isPresented: $showSuccessAlert) {
            Button("확인") {
                dismiss()
            }
        } message: {
            Text("프로필 설정이 완료되었습니다.")
        }
        .task {
            await vm.checkOnboardingNeeded()
        }
    }
}

private struct ProfileImageSection: View {
    @ObservedObject var vm: OnBoardingViewModel
    @Binding var pickerItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("프로필 사진")
                .font(.headline)

            ZStack {
                if let data = vm.previewImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                        .foregroundStyle(Color(.systemGray4))
                        .frame(height: 180)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.system(size: 26, weight: .semibold))
                                Text("프로필 이미지를 선택해 주세요")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                }

                if vm.isProcessingImage {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.black.opacity(0.05))
                            .frame(height: 180)
                        ProgressView()
                    }
                    .transition(.opacity)
                }
            }

            PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                Label("사진 선택", systemImage: "photo.fill.on.rectangle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
            }
            .onChange(of: pickerItem) { _, newItem in
                guard let item = newItem else { vm.setProfileImage(data: nil); return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        await MainActor.run { vm.setProfileImage(data: data) }
                    }
                }
            }

            Text("이미지 형식: jpg, jpeg, png | 최대 200KB (권장 100KB)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if vm.profileImageData != nil && !vm.isImageValid {
                Text("이미지 용량이 너무 큽니다. 200KB 이하로 줄여주세요.")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }
}

private struct NicknameSection: View {
    @ObservedObject var vm: OnBoardingViewModel
    @FocusState var focusedField: OnBoardingView.Field?

    private var isNickValid: Bool { vm.validateNick(vm.nick) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("닉네임")
                .font(.headline)
            TextField("닉네임을 입력해 주세요", text: $vm.nick)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .focused($focusedField, equals: .nick)

            if !isNickValid {
                Text("닉네임은 공백 없이 입력해야 하며,\n특수 문자는 사용할 수 없습니다.")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            Text("사용 불가 문자: . , ? * - @ + ^ $ { } ( ) | [ ] \\")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PhoneSection: View {
    @ObservedObject var vm: OnBoardingViewModel
    @FocusState var focusedField: OnBoardingView.Field?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("연락처")
                .font(.headline)
            TextField("숫자만 입력 (예: 01012345678)", text: $vm.phoneNum)
                .keyboardType(.numberPad)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .focused($focusedField, equals: .phone)
        }
    }
}

private struct BirthSection: View {
    @ObservedObject var vm: OnBoardingViewModel
    @Binding var formattedBirthDate: String
    @FocusState var focusedField: OnBoardingView.Field?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("생년월일")
                .font(.headline)
            VStack(spacing: 4) {
                DatePicker("", selection: $vm.birthDate, displayedComponents: .date)
                    .labelsHidden()
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                Text(formattedBirthDate)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
            }
            .focused($focusedField, equals: .birth)
        }
    }
}

private struct GenderSection: View {
    @ObservedObject var vm: OnBoardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("성별")
                .font(.headline)
            Picker("성별", selection: $vm.gender) {
                ForEach(OnBoardingViewModel.GenderOption.allCases) { option in
                    Text(option.display).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

#Preview {
    OnBoardingView()
}
