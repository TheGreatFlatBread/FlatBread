//
//  SignUpView.swift
//  FlatBread
//
//  Created by hwan on 11/27/25.
//

import SwiftUI

struct SignUpView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SignUpViewModel
    @FocusState private var focusedField: Field?

    let onSignUpSuccess: () -> Void

    init(onSignUpSuccess: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: SignUpViewModel())
        self.onSignUpSuccess = onSignUpSuccess
    }

    enum Field: Hashable {
        case email, password, passwordConfirm, nickname
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("회원가입")
                        .font(FBTypography.heading)

                    Text("FlatBread와 함께 시작하세요")
                        .font(FBTypography.body)
                        .foregroundStyle(FBColor.Text.secondary)
                }
                .padding(.top, 40)

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        FBTextField(
                            title: "이메일",
                            text: $viewModel.email,
                            placeholder: "example@email.com",
                            keyboardType: .emailAddress,
                            validationMessage: viewModel.emailValidationMessage,
                            isValid: viewModel.isEmailValid,
                            focused: $focusedField,
                            field: .email
                        )
                        .onChange(of: viewModel.email) { _, _ in
                            viewModel.validateEmailFormat()
                        }

                        if viewModel.isEmailValid && !viewModel.emailValidationMessage.contains("사용 가능") {
                            Button {
                                Task {
                                    await viewModel.checkEmailDuplicate()
                                }
                            } label: {
                                HStack {
                                    if viewModel.isCheckingEmailDuplicate {
                                        ProgressView()
                                            .controlSize(.small)
                                    }
                                    Text("중복 확인")
                                        .font(FBTypography.label)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(FBColor.Brand.primary.opacity(0.1))
                                .foregroundStyle(FBColor.Brand.primary)
                                .cornerRadius(FBRadius.sm)
                            }
                            .disabled(viewModel.isCheckingEmailDuplicate)
                        }
                    }

                    FBSecureField(
                        title: "비밀번호",
                        text: $viewModel.password,
                        placeholder: "8자 이상, 영문+숫자+특수문자",
                        validationMessage: viewModel.passwordValidationMessage,
                        isValid: viewModel.isPasswordValid,
                        focused: $focusedField,
                        field: .password
                    )
                    .onChange(of: viewModel.password) { _, _ in
                        viewModel.validatePassword()
                    }

                    FBSecureField(
                        title: "비밀번호 확인",
                        text: $viewModel.passwordConfirm,
                        placeholder: "비밀번호를 다시 입력하세요",
                        validationMessage: viewModel.passwordConfirmValidationMessage,
                        isValid: viewModel.isPasswordConfirmValid,
                        focused: $focusedField,
                        field: .passwordConfirm
                    )
                    .onChange(of: viewModel.passwordConfirm) { _, _ in
                        viewModel.validatePasswordConfirm()
                    }

                    FBTextField(
                        title: "닉네임",
                        text: $viewModel.nickname,
                        placeholder: "1~10자",
                        validationMessage: viewModel.nicknameValidationMessage,
                        isValid: viewModel.isNicknameValid,
                        focused: $focusedField,
                        field: .nickname
                    )
                    .onChange(of: viewModel.nickname) { _, _ in
                        viewModel.validateNickname()
                    }

                    FBButton(
                        title: "회원가입",
                        isLoading: viewModel.isSigningUp,
                        isEnabled: viewModel.canSignUp
                    ) {
                        Task {
                            await viewModel.signUp()
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 40)
            }
            .tint(FBColor.Brand.primary)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
        .alert("알림", isPresented: $viewModel.showingAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
        .onChange(of: viewModel.isSignUpSucceed) { _, newValue in
            if newValue {
                onSignUpSuccess()
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView(onSignUpSuccess: {})
    }
}
