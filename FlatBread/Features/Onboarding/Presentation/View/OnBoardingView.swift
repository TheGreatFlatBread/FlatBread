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

    enum Field { case nick, phone, birth }

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
                        VStack(alignment: .leading, spacing: 10) {
                            Text("프로필 사진")
                                .font(.headline)

                            ZStack {
                                if let data = vm.profileImageData, let uiImage = UIImage(data: data) {
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
                        }
                        .padding(.horizontal, 16)

                        // MARK: - 닉네임
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
                        }
                        .padding(.horizontal, 16)

                        // MARK: - 연락처
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
                        .padding(.horizontal, 16)

                        // MARK: - 생년월일
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
                                Text(vm.birthDate, formatter: {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "yyyy-MM-dd"
                                    return formatter
                                }())
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 14)
                            }
                            .focused($focusedField, equals: .birth)
                        }
                        .padding(.horizontal, 16)

                        // MARK: - 성별
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
                            // On success, server now has info1 set. Route to Home.
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
        .task {
            await vm.checkOnboardingNeeded()
        }
    }
}

#Preview {
    OnBoardingView()
}
