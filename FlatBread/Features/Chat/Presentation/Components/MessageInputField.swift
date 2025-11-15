//
//  ChatInputView.swift
//  FlatBread
//
//  Created by hwan on 11/14/25.
//

import SwiftUI

struct MessageInputField: View {
    @Binding var text: String
    @Binding var selectedImageURLs: [String]
    @FocusState.Binding var isFocused: Bool

    let onSend: () -> Void
    let onRemoveImage: (Int) -> Void
    let onCameraButtonTap: () -> Void
    let onImageButtonTap: () -> Void
    let onVoiceButtonTap: () -> Void
    let onEmojiButtonTap: () -> Void
    let onPlusButtonTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if !selectedImageURLs.isEmpty {
                ImageListCell(
                    selectedImageURLs: selectedImageURLs,
                    onRemoveImage: onRemoveImage
                )
            }

            HStack(alignment: .center, spacing: 12) {
                Button(action: onCameraButtonTap) {
                    Circle()
                        .fill(Color("juwhang"))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        )
                }

                HStack(spacing: 8) {
                    TextField("메시지 보내기...", text: $text, axis: .vertical)
                        .lineLimit(1...5)
                        .frame(minHeight: 36)
                        .focused($isFocused)
                        .submitLabel(.send)
                        .onSubmit {
                            onSend()
                        }

                    if !text.isEmpty || !selectedImageURLs.isEmpty {
                        Button(action: onSend) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(Color("juwhang"))
                                .font(.system(size: 20))
                        }
                    }
//                    else {
//                        HStack(spacing: 12) {
//                            Button(action: onVoiceButtonTap) {
//                                Image(systemName: "mic.fill")
//                                    .foregroundColor(.gray)
//                                    .font(.system(size: 20))
//                            }
//
//                            Button(action: onImageButtonTap) {
//                                Image(systemName: "photo")
//                                    .foregroundColor(.gray)
//                                    .font(.system(size: 20))
//                            }
//
//                            Button(action: onEmojiButtonTap) {
//                                Image(systemName: "face.smiling")
//                                    .foregroundColor(.gray)
//                                    .font(.system(size: 20))
//                            }
//
//                            Button(action: onPlusButtonTap) {
//                                Image(systemName: "plus.circle")
//                                    .foregroundColor(.gray)
//                                    .font(.system(size: 20))
//                            }
//                        }
//                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(uiColor: .systemGray6))
                .cornerRadius(20)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(uiColor: .systemBackground))
        }
    }
}


private struct ImageListCell: View {
    let selectedImageURLs: [String]
    var onRemoveImage: ((Int) -> Void)
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(selectedImageURLs.indices, id: \.self) { index in
                    ZStack(alignment: .topTrailing) {
                        RemoteImage(
                            url: selectedImageURLs[index],
                            displayMode: .thumbnail(CGSize(width: 80, height: 80))
                        ) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        Button(action: {
                            onRemoveImage(index)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .padding(4)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(uiColor: .systemBackground))

        Divider()
    }
}

#Preview("Full Featured") {
    VStack {
        Spacer()
        MessageInputField(
            text: .constant(""),
            selectedImageURLs: .constant([]),
            isFocused: FocusState<Bool>().projectedValue,
            onSend: { print("Send") },
            onRemoveImage: { print("Remove \($0)") },
            onCameraButtonTap: { print("Camera") },
            onImageButtonTap: { print("Image") },
            onVoiceButtonTap: { print("Voice") },
            onEmojiButtonTap: { print("Emoji") },
            onPlusButtonTap: { print("Plus") }
        )
    }
}

#Preview("With Text") {
    VStack {
        Spacer()
        MessageInputField(
            text: .constant("안녕하세요"),
            selectedImageURLs: .constant([]),
            isFocused: FocusState<Bool>().projectedValue,
            onSend: { print("Send") },
            onRemoveImage: { print("Remove \($0)") },
            onCameraButtonTap: { print("Camera") },
            onImageButtonTap: { print("Image") },
            onVoiceButtonTap: { print("Voice") },
            onEmojiButtonTap: { print("Emoji") },
            onPlusButtonTap: { print("Plus") }
        )
    }
}

#Preview("With Images") {
    VStack {
        Spacer()
        MessageInputField(
            text: .constant(""),
            selectedImageURLs: .constant([]),
            isFocused: FocusState<Bool>().projectedValue,
            onSend: { print("Send") },
            onRemoveImage: { print("Remove \($0)") },
            onCameraButtonTap: { print("Camera") },
            onImageButtonTap: { print("Image") },
            onVoiceButtonTap: { print("Voice") },
            onEmojiButtonTap: { print("Emoji") },
            onPlusButtonTap: { print("Plus") }
        )
    }
}
