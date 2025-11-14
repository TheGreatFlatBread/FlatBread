//
//  LoginViewModel.swift
//  FlatBread
//
//  Created by 김민성 on 11/12/25.
//

import AuthenticationServices
import Combine
import Foundation

final class LoginViewModel: NSObject, ObservableObject {
    
    private let tokenStorage: any TokenStorage
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    
    init(tokenStorage: any TokenStorage) {
        self.tokenStorage = tokenStorage
    }
    
    @Published var showingAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var isLoginSucceed: Bool = false
    
    func handleAppleSignInResult(result: Result<ASAuthorization, any Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                // No-op
                // 이 경우에 별도 Alert가 필요하다고 생각하면 기능 추가
                return
            }
            guard let tokenData = appleIDCredential.identityToken else {
                alertMessage = SocialLoginError.appleIdTokenNil.localizedDescription
                showingAlert = true
                return
            }
            guard let idToken = String(data: tokenData, encoding: .utf8) else {
                alertMessage = SocialLoginError.appleIDTokenEncodingFailed.localizedDescription
                showingAlert = true
                return
            }
            
            #if DEBUG
            print("---- 애플 소셜 로그인 성공----")
            print("token: \(idToken)")
            if let fullName = appleIDCredential.fullName {
                print("fullName: \(fullName)")
            }
            if let email = appleIDCredential.email {
                print("email: \(email)")
            }
            #endif
            
            Task {
                await appleLogin(idToken: idToken)
                isLoginSucceed = true
            }
            
            
        case .failure(let error):
            if let authError = error as? ASAuthorizationError {
                if authError.code == .canceled {
                    print("사용자가 Apple Sign In 취소함")
                    return
                }
                self.alertMessage = authError.localizedDescription
                self.showingAlert = true
            } else {
                // ASAuthorizationError가 아닌 다른 종류의 오류(예: 일반 네트워크 오류, 커스텀 오류 등) 처리
                print("알 수 없는 로그인 오류 발생: \(error.localizedDescription)")
                self.alertMessage = error.localizedDescription
                self.showingAlert = true
            }
        }
    }
    
    
    private func appleLogin(idToken: String) async {
        do {
            let signInInfo = try await networkService.request(
                UserRouter.loginApple(idToken: idToken),
                responseType: UserSignUpResponseDTO.self,
                interceptorType: .onlyNetworkRetrier
            )
            await tokenStorage.saveToken(
                access: signInInfo.accessToken!,
                refresh: signInInfo.refreshToken!,
            )
            #if DEBUG
            print("accessToken: \(signInInfo.accessToken!)")
            #endif
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
    
}
