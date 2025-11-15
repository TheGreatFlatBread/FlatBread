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
    
    var body: some View {
        VStack {
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    viewModel.handleAppleSignInResult(result: result)
                }
            )
            .frame(height: 55)
            .padding(.horizontal, 24)
        }
        .alert("애플 로그인 실패", isPresented: $viewModel.showingAlert) {
            Button("확인", role: .cancel) { return }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
    
}

#Preview {
    @Previewable @State var isLoginSucceed: Bool = false
    let viewModel = LoginViewModel(tokenStorage: DefaultTokenStorage())
    LoginView(isLoginSucceed: $isLoginSucceed, viewModel: viewModel)
}
