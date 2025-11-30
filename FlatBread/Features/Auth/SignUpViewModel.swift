//
//  SignUpViewModel.swift
//  FlatBread
//
//  Created by hwan on 11/27/25.
//

import Foundation
import Combine

final class SignUpViewModel: ObservableObject {

    private let tokenStorage = DefaultTokenStorage()
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()

    init() { }

    @Published var showingAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var isSignUpSucceed: Bool = false

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var passwordConfirm: String = ""
    @Published var nickname: String = ""

    @Published var emailValidationMessage: String = ""
    @Published var passwordValidationMessage: String = ""
    @Published var passwordConfirmValidationMessage: String = ""
    @Published var nicknameValidationMessage: String = ""

    @Published var isEmailValid: Bool = false
    @Published var isPasswordValid: Bool = false
    @Published var isPasswordConfirmValid: Bool = false
    @Published var isNicknameValid: Bool = false

    @Published var isSigningUp: Bool = false
    @Published var isCheckingEmailDuplicate: Bool = false
    
    func validateEmailFormat() {
        let result = EmailValidator.validateFormat(email)
        emailValidationMessage = result.message
        isEmailValid = result.isValid
    }

    @MainActor
    func checkEmailDuplicate() async {
        guard isEmailValid else { return }

        isCheckingEmailDuplicate = true
        defer { isCheckingEmailDuplicate = false }

        do {
            _ = try await networkService.request(
                UserRouter.validation(email: email),
                responseType: EmailValidationResponseDTO.self,
                interceptorType: .onlyNetworkRetrier
            )
            emailValidationMessage = "사용 가능한 이메일입니다"
            isEmailValid = true
        } catch {
            emailValidationMessage = "이미 사용 중인 이메일입니다"
            isEmailValid = false
        }
    }
    
    func validatePassword() {
        let result = PasswordValidator.validate(password)
        passwordValidationMessage = result.message
        isPasswordValid = result.isValid
        validatePasswordConfirm()
    }
    
    func validatePasswordConfirm() {
        let result = PasswordValidator.validateConfirmation(password: password, confirmation: passwordConfirm)
        passwordConfirmValidationMessage = result.message
        isPasswordConfirmValid = result.isValid
    }
    
    func validateNickname() {
        let result = NicknameValidator.validate(nickname)
        nicknameValidationMessage = result.message
        isNicknameValid = result.isValid
    }
    
    var canSignUp: Bool {
        isEmailValid &&
        isPasswordValid &&
        isPasswordConfirmValid &&
        isNicknameValid &&
        !isSigningUp
    }

    @MainActor
    func signUp() async {
        guard canSignUp else { return }

        isSigningUp = true
        defer { isSigningUp = false }

        do {
            let request = UserSignUpRequestDTO(
                email: email,
                password: password,
                nick: nickname
            )

            let response = try await networkService.request(
                UserRouter.signUp(request: request),
                responseType: UserSignUpResponseDTO.self,
                interceptorType: .onlyNetworkRetrier
            )

            await tokenStorage.saveToken(
                access: response.accessToken!,
                refresh: response.refreshToken!
            )

            #if DEBUG
            print("회원가입 성공: \(response)")
            #endif

            isSignUpSucceed = true
        } catch {
            print("회원가입 실패: \(error)")
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    func resetForm() {
        email = ""
        password = ""
        passwordConfirm = ""
        nickname = ""
        emailValidationMessage = ""
        passwordValidationMessage = ""
        passwordConfirmValidationMessage = ""
        nicknameValidationMessage = ""
        isEmailValid = false
        isPasswordValid = false
        isPasswordConfirmValid = false
        isNicknameValid = false
    }
}
