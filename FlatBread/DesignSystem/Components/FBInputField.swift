//
//  FBInputField.swift
//  FlatBread
//
//  Created by andev on 4/2/26.
//

import SwiftUI

struct FBTextField<Field: Hashable>: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var validationMessage: String = ""
    var isValid: Bool = false
    @FocusState.Binding var focused: Field?
    let field: Field

    var body: some View {
        VStack(alignment: .leading, spacing: FBSpacing.xs) {
            Text(title)
                .font(FBTypography.label)
                .foregroundStyle(FBColor.Text.secondary)

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(FBColor.Background.input)
                .cornerRadius(FBRadius.md)
                .overlay {
                    RoundedRectangle(cornerRadius: FBRadius.md)
                        .stroke(borderColor, lineWidth: 1.5)
                }
                .focused($focused, equals: field)

            if !validationMessage.isEmpty {
                HStack(spacing: FBSpacing.xxs) {
                    Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(FBTypography.caption)
                    Text(validationMessage)
                        .font(FBTypography.caption)
                }
                .foregroundStyle(isValid ? FBColor.State.success : FBColor.State.error)
            }
        }
    }

    private var borderColor: Color {
        if focused == field {
            return FBColor.Brand.primary
        } else if !validationMessage.isEmpty {
            return isValid ? FBColor.State.success : FBColor.State.error
        } else {
            return .clear
        }
    }
}

struct FBSecureField<Field: Hashable>: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var validationMessage: String = ""
    var isValid: Bool = false
    @FocusState.Binding var focused: Field?
    let field: Field
    @State private var isPasswordVisible: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: FBSpacing.xs) {
            Text(title)
                .font(FBTypography.label)
                .foregroundStyle(FBColor.Text.secondary)

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
                        .foregroundStyle(FBColor.Text.secondary)
                }
            }
            .padding()
            .background(FBColor.Background.input)
            .cornerRadius(FBRadius.md)
            .overlay {
                RoundedRectangle(cornerRadius: FBRadius.md)
                    .stroke(borderColor, lineWidth: 1.5)
            }
            .focused($focused, equals: field)

            if !validationMessage.isEmpty {
                HStack(spacing: FBSpacing.xxs) {
                    Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(FBTypography.caption)
                    Text(validationMessage)
                        .font(FBTypography.caption)
                }
                .foregroundStyle(isValid ? FBColor.State.success : FBColor.State.error)
            }
        }
    }

    private var borderColor: Color {
        if focused == field {
            return FBColor.Brand.primary
        } else if !validationMessage.isEmpty {
            return isValid ? FBColor.State.success : FBColor.State.error
        } else {
            return .clear
        }
    }
}
