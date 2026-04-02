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

struct FBPlainTextField<Field: Hashable>: View {
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    @FocusState.Binding var focused: Field?
    let field: Field
    var horizontalPadding: CGFloat = 14
    var verticalPadding: CGFloat = 14

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: FBRadius.lg, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .focused($focused, equals: field)
    }

    private var borderColor: Color {
        focused == field ? FBColor.Brand.primary : FBColor.Border.subtle
    }
}

struct FBTextEditorField<Field: Hashable>: View {
    @Binding var text: String
    let placeholder: String
    var minHeight: CGFloat = 160
    @FocusState.Binding var focused: Field?
    let field: Field
    var padding: CGFloat = 10

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .frame(minHeight: minHeight, maxHeight: .infinity)
                .padding(padding)
                .background(
                    RoundedRectangle(cornerRadius: FBRadius.lg, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
                .focused($focused, equals: field)

            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(FBColor.Text.secondary)
                    .font(.body)
                    .padding(.horizontal, padding + 4)
                    .padding(.vertical, padding + 4)
                    .allowsHitTesting(false)
            }
        }
    }

    private var borderColor: Color {
        focused == field ? FBColor.Brand.primary : FBColor.Border.subtle
    }
}
