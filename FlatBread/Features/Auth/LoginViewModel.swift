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
    private let tokenCoordiantor = NetworkServiceFactory.shared.getTokenCoordinator()

    init(tokenStorage: any TokenStorage) {
        self.tokenStorage = tokenStorage
    }

    @Published var showingAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var isLoginSucceed: Bool = false
    @Published var isCheckingLoginStatus: Bool = true

    @Published var email: String = ""
    @Published var password: String = ""

    @Published var emailValidationMessage: String = ""
    @Published var isEmailValid: Bool = false

    @Published var isLoggingIn: Bool = false

    @MainActor
    func checkLoginStatus() async {
        defer { isCheckingLoginStatus = false }

        let emailSuccess = await attemptEmailAutoLogin()
        if emailSuccess {
            return
        }

        let appleSuccess = await attemptAppleAutoLogin()
        if appleSuccess {
            return
        }
        print("[Login] 자동 로그인 불가 - 로그인 필요")
    }

    @MainActor
    private func attemptEmailAutoLogin() async -> Bool {
        if await tokenStorage.getAppleUserID() != nil {
            return false
        }
        
        guard let refreshToken = await tokenStorage.getRefreshToken(),
              !refreshToken.isEmpty else {
            return false
        }
        
        guard let userId = await tokenStorage.getUserID(),
              !userId.isEmpty else {
            return false
        }

        do {
            let access = try await tokenCoordiantor.refreshToken()
            // UserSession 복원
            UserSession.shared.login(userId: userId, sendPendingToken: true)

            // 자동 로그인 후 FCM 토큰 재전송 (중요!)
            sendFCMTokenIfAvailable()

            isLoginSucceed = true
            return true
        } catch {
            await tokenStorage.clearTokens()
            UserSession.shared.logout()
            return false
        }
    }

    @MainActor
    private func attemptAppleAutoLogin() async -> Bool {
        guard let appleUserID = await tokenStorage.getAppleUserID() else {
            return false
        }

        guard let refreshToken = await tokenStorage.getRefreshToken(),
              !refreshToken.isEmpty else {
            return false
        }

        let state = await checkCredentialState(userID: appleUserID)

        switch state {
        case .authorized:
            do {
                _ = try await tokenCoordiantor.refreshToken()

                // UserSession 복원
                if let userId = await tokenStorage.getUserID() {
                    UserSession.shared.login(userId: userId, sendPendingToken: true)
                }

                // 자동 로그인 후 FCM 토큰 재전송
                sendFCMTokenIfAvailable()

                isLoginSucceed = true
                return true
            } catch {
                await tokenStorage.clearTokens()
                UserSession.shared.logout()
                isLoginSucceed = false
                alertMessage = "세션이 만료되어 다시 로그인해야 합니다."
                showingAlert = true
                return false
            }

        case .revoked, .notFound, .transferred:
            await tokenStorage.clearTokens()
            UserSession.shared.logout()
            return false

        @unknown default:
            return false
        }
    }

    private func checkCredentialState(userID: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { state, _ in
                continuation.resume(returning: state)
            }
        }
    }

    /// 현재 FCM 토큰이 있으면 백엔드로 전송
    /// - 자동 로그인 후, 수동 로그인 후 호출
    /// - userId가 바뀌었을 수 있으므로 항상 전송
    private func sendFCMTokenIfAvailable() {
        guard let fcmToken = UserDefaults.standard.string(forKey: "fcmToken"),
              !fcmToken.isEmpty else {
            print("[Login] FCM 토큰 없음 - 전송 건너뛰기")
            return
        }

        print("[Login] FCM 토큰 재전송 (자동/수동 로그인 후)")
        // AppDelegate의 sendTokenToBackend 호출
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.sendTokenToBackend(fcmToken: fcmToken)
        }
    }
    
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
                await tokenStorage.saveAppleUserID(appleIDCredential.user)
                await appleLogin(idToken: idToken)
            }
            
            
        case .failure(let error):
            if let authError = error as? ASAuthorizationError {
                if authError.code == .canceled {
                    print("사용자가 Apple Sign In 취소함")
                    return
                } else if authError.code == .unknown {
                    print("로그인 프로세스 중 credential 상태 확인 실패한 것")
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
                refresh: signInInfo.refreshToken!
            )

            // userId 저장
            if let userId = signInInfo.userID {
                await tokenStorage.saveUserID(userId)

                // UserSession에 로그인 상태 저장 + Pending FCM 토큰 전송
                UserSession.shared.login(userId: userId, sendPendingToken: true)
            }

            // FCM 토큰 재전송 (수동 로그인 후)
            sendFCMTokenIfAvailable()

            #if DEBUG
            print("[Login] Apple 로그인 성공")
            print("   accessToken: \(signInInfo.accessToken!)")
            print("   userId: \(signInInfo.userID ?? "nil")")
            #endif

            isLoginSucceed = true
        } catch {
            print("[Login] Apple 로그인 실패: \(error)")
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

}

// MARK: - Email/Password Login
extension LoginViewModel {

    func validateEmailFormat() {
        let result = EmailValidator.validateFormat(email)
        emailValidationMessage = result.message
        isEmailValid = result.isValid
    }

    var canLogin: Bool {
        return !email.isEmpty && !password.isEmpty && !isLoggingIn
    }

    @MainActor
    func login() async {
        guard canLogin else { return }

        isLoggingIn = true
        defer { isLoggingIn = false }

        do {
            let response = try await networkService.request(
                UserRouter.login(email: email, password: password),
                responseType: UserSignUpResponseDTO.self,
                interceptorType: .onlyNetworkRetrier
            )

            await tokenStorage.saveToken(
                access: response.accessToken!,
                refresh: response.refreshToken!
            )

            if let userId = response.userID {
                await tokenStorage.saveUserID(userId)
                UserSession.shared.login(userId: userId, sendPendingToken: true)
            }

            // FCM 토큰 재전송 (수동 로그인 후)
            sendFCMTokenIfAvailable()

            #if DEBUG
            print("[Login] Email 로그인 성공")
            print("   email: \(response.email ?? "nil")")
            print("   userId: \(response.userID ?? "nil")")
            #endif

            isLoginSucceed = true
        } catch {
            print("로그인 실패: \(error)")
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    // MARK: - Reset
    func resetLoginForm() {
        email = ""
        password = ""
    }
}
