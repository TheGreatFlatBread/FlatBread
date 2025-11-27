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
                        .font(.system(size: 28, weight: .bold))

                    Text("FlatBread와 함께 시작하세요")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        CustomTextField(
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
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .cornerRadius(8)
                            }
                            .disabled(viewModel.isCheckingEmailDuplicate)
                        }
                    }

                    CustomSecureField(
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

                    CustomSecureField(
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

                    CustomTextField(
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

                    Button {
                        Task {
                            await viewModel.signUp()
                        }
                    } label: {
                        HStack {
                            if viewModel.isSigningUp {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("회원가입")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(viewModel.canSignUp ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!viewModel.canSignUp)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 40)
            }
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

fileprivate struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var validationMessage: String = ""
    var isValid: Bool = false
    @FocusState.Binding var focused: SignUpView.Field?
    let field: SignUpView.Field

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(borderColor, lineWidth: 1.5)
                }
                .focused($focused, equals: field)

            if !validationMessage.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(validationMessage)
                        .font(.caption)
                }
                .foregroundStyle(isValid ? .green : .red)
            }
        }
    }

    private var borderColor: Color {
        if focused == field {
            return .blue
        } else if !validationMessage.isEmpty {
            return isValid ? .green : .red
        } else {
            return .clear
        }
    }
}

fileprivate struct CustomSecureField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var validationMessage: String = ""
    var isValid: Bool = false
    @FocusState.Binding var focused: SignUpView.Field?
    let field: SignUpView.Field
    @State private var isPasswordVisible: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            HStack {
                if isPasswordVisible {
                    TextField(placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField(placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: 1.5)
            }
            .focused($focused, equals: field)

            if !validationMessage.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(validationMessage)
                        .font(.caption)
                }
                .foregroundStyle(isValid ? .green : .red)
            }
        }
    }

    private var borderColor: Color {
        if focused == field {
            return .blue
        } else if !validationMessage.isEmpty {
            return isValid ? .green : .red
        } else {
            return .clear
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView(onSignUpSuccess: {})
    }
}
