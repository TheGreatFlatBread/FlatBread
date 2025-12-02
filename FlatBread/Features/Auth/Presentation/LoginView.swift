//
//  LoginView.swift
//  FlatBread
//
//  Created by 김민성 on 11/12/25.
//

import AuthenticationServices
import SwiftUI

struct LoginView: View {

    @Binding var isLoginSucceed: Bool
    @ObservedObject var viewModel: LoginViewModel
    @FocusState private var focusedField: Field?

    init(isLoginSucceed: Binding<Bool>, viewModel: LoginViewModel) {
        self._isLoginSucceed = isLoginSucceed
        self.viewModel = viewModel
    }

    enum Field: Hashable {
        case email, password
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo & Title
                    VStack(spacing: 12) {
                        Image("FB_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)

                        Text("플랫브레드")
                            .font(.system(size: 32, weight: .bold))
                    }
                    .padding(.top, 60)

                    // Login Content
                    loginContent
                        .padding(.horizontal, 24)

                    // Divider with OR
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        Text("또는")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 24)

                    // Social Login Icons
                    socialLoginButtons

                    // Sign Up Link
                    NavigationLink {
                        SignUpView {
                            isLoginSucceed = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("계정이 없으신가요?")
                                .foregroundStyle(Color.black)
                                .opacity(0.5)
                            Text("회원가입")
                                .foregroundStyle(Color("juhwang"))
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 14))
                    }

                    Spacer(minLength: 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .alert("로그인 실패", isPresented: $viewModel.showingAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
        }
    }

    private var socialLoginButtons: some View {
        HStack(spacing: 20) {
            // Kakao Login Button
            Button {
                print("Kakao login tapped")
            } label: {
                Circle()
                    .fill(.yellow)
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "message.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.black)
                    }
            }
            
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    viewModel.handleAppleSignInResult(result: result)
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .fill(.black)
                    .overlay {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                    }
                    .allowsHitTesting(false)
            }
        }
    }

    private var loginContent: some View {
        VStack(spacing: 16) {
            // Email
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

            // Password
            CustomSecureField(
                title: "비밀번호",
                text: $viewModel.password,
                placeholder: "비밀번호를 입력하세요",
                focused: $focusedField,
                field: .password
            )

            // Login Button
            Button {
                Task {
                    await viewModel.login()
                }
            } label: {
                HStack {
                    if viewModel.isLoggingIn {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("로그인")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.canLogin ? Color("juhwang") : Color.gray.opacity(0.3))
                .foregroundStyle(.white)
                .cornerRadius(10)
            }
            .disabled(!viewModel.canLogin)
        }
        .tint(Color("juhwang"))
    }

}

fileprivate struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var validationMessage: String = ""
    var isValid: Bool = false
    @FocusState.Binding var focused: LoginView.Field?
    let field: LoginView.Field

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
            return Color("juhwang")
        } else if !validationMessage.isEmpty {
            return isValid ? .green : .red
        } else {
            return .clear
        }
    }
}

// MARK: - Custom Secure Field
fileprivate struct CustomSecureField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var validationMessage: String = ""
    var isValid: Bool = false
    @FocusState.Binding var focused: LoginView.Field?
    let field: LoginView.Field
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
            return Color("juhwang")
        } else if !validationMessage.isEmpty {
            return isValid ? .green : .red
        } else {
            return .clear
        }
    }
}

#Preview {
    @Previewable @State var isLoginSucceed: Bool = false
    let viewModel = LoginViewModel(tokenStorage: DefaultTokenStorage())
    LoginView(isLoginSucceed: $isLoginSucceed, viewModel: viewModel)
}
