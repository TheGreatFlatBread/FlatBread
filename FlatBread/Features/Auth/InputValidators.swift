//
//  InputValidators.swift
//  FlatBread
//
//  Created by hwan on 11/24/25.
//

import Foundation

struct ValidationResult {
    let isValid: Bool
    let message: String

    static func valid(_ message: String = "") -> ValidationResult {
        ValidationResult(isValid: true, message: message)
    }

    static func invalid(_ message: String) -> ValidationResult {
        ValidationResult(isValid: false, message: message)
    }
}

struct EmailValidator {

    static func validateFormat(_ email: String) -> ValidationResult {
        if email.isEmpty {
            return .invalid("")
        }
        
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        if !emailPredicate.evaluate(with: email) {
            return .invalid("올바른 이메일 형식이 아닙니다")
        }

        return .valid()
    }
}

enum PasswordValidator {

    static func validate(_ password: String) -> ValidationResult {
        if password.isEmpty {
            return .invalid("")
        }

        var validationErrors: [String] = []
        
        if password.count < 8 {
            validationErrors.append("8자 이상")
        }
        
        let letterRegex = ".*[A-Za-z]+.*"
        if !NSPredicate(format: "SELF MATCHES %@", letterRegex).evaluate(with: password) {
            validationErrors.append("영문 포함")
        }
        
        let numberRegex = ".*[0-9]+.*"
        if !NSPredicate(format: "SELF MATCHES %@", numberRegex).evaluate(with: password) {
            validationErrors.append("숫자 포함")
        }
        
        let specialCharRegex = ".*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]+.*"
        if !NSPredicate(format: "SELF MATCHES %@", specialCharRegex).evaluate(with: password) {
            validationErrors.append("특수문자 포함")
        }

        if validationErrors.isEmpty {
            return .valid("사용 가능한 비밀번호입니다")
        } else {
            return .invalid("비밀번호는 \(validationErrors.joined(separator: ", ")) 필요")
        }
    }

    static func validateConfirmation(password: String, confirmation: String) -> ValidationResult {
        if confirmation.isEmpty {
            return .invalid("")
        }

        if password != confirmation {
            return .invalid("비밀번호가 일치하지 않습니다")
        }

        return .valid("비밀번호가 일치합니다")
    }
}

enum NicknameValidator {
    static func validate(_ nickname: String) -> ValidationResult {
        if nickname.isEmpty {
            return .invalid("")
        }

        if nickname.count < 1 || nickname.count > 10 {
            return .invalid("닉네임은 1~10자 사이여야 합니다")
        }

        return .valid()
    }
}
