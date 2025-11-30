//
//  ChatBubbleView.swift
//  FlatBread
//
//  Created by hwan on 11/12/25.
//

import SwiftUI

struct ChatBubbleCell: View {
    let config: MessageDisplayConfig
    let isMyMessage: Bool
    var onRetry: ((ChatMessageModel) -> Void)? = nil

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isMyMessage {
                Spacer(minLength: 60)
                ChatMeBubble(
                    message: config.message,
                    showTime: config.showTime,
                    onRetry: onRetry
                )
            } else {
                ChatOtherBubble(
                    message: config.message,
                    showProfile: config.showProfile,
                    showNickname: config.showNickname,
                    showTime: config.showTime
                )
                Spacer(minLength: 60)
            }
        }
    }
}

private struct ChatMeBubble: View {
    let message: ChatMessageModel
    let showTime: Bool
    var onRetry: ((ChatMessageModel) -> Void)? = nil

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            VStack(alignment: .trailing, spacing: 2) {
                if let sendStatus = message.sendStatus {
                    statusView(for: sendStatus)
                }

                Text(message.createdAt.toTimeString())
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.gray)
                    .opacity(showTime ? 1 : 0)
            }

            VStack(alignment: .trailing, spacing: 4) {
                switch message.messegeType {
                case .filesWithString(let files, let _message):
                    if !files.isEmpty {
                        ChatImageGridCell(imageURLs: files)
                    } else if message.sendStatus == .sending && files.isEmpty {
                        ProgressView()
                            .frame(width: 200, height: 200)
                            .background(Color(uiColor: .systemGray6))
                            .cornerRadius(12)
                    }
                    MessageMeView(message: _message)
                case .files(let files):
                    if !files.isEmpty {
                        ChatImageGridCell(imageURLs: files)
                    } else if message.sendStatus == .sending && files.isEmpty {
                        ProgressView()
                            .frame(width: 200, height: 200)
                            .background(Color(uiColor: .systemGray6))
                            .cornerRadius(12)
                    }
                case .text(let message):
                    MessageMeView(message: message)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if message.sendStatus == .failed, let onRetry = onRetry {
                onRetry(message)
            }
        }
    }

    @ViewBuilder
    private func statusView(for status: MessageSendStatus) -> some View {
        switch status {
        case .sending:
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.7)
                Text("전송 중")
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(.gray)
            }
        case .sent:
            EmptyView()
        case .failed:
            Button(action: {
                if let onRetry = onRetry {
                    onRetry(message)
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.red)
                    Text("재전송")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.red)
                }
            }
        }
    }
}

private struct ChatOtherBubble: View {
    let message: ChatMessageModel
    let showProfile: Bool
    let showNickname: Bool
    let showTime: Bool

    var body: some View {
        if showProfile {
            VStack {
                if let profileImageURL = message.sender.profileImage, !profileImageURL.isEmpty {
                    RemoteImage(
                        url: profileImageURL,
                        displayMode: .thumbnail(CGSize(width: 108, height: 108)))
                    { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.33)
                            )
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(message.sender.nick.prefix(1))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
                Spacer()
            }
        } else {
            Spacer()
                .frame(width: 36)
        }

        VStack(alignment: .leading, spacing: 4) {
            if showNickname {
                Text(message.sender.nick)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.gray)
            }

            HStack(alignment: .bottom, spacing: 6) {
                VStack(alignment: .leading, spacing: 4) {
                    switch message.messegeType {
                    case .filesWithString(let files, let message):
                        ChatImageGridCell(imageURLs: files)
                        MessageView(message: message)
                    case .files(let files):
                        ChatImageGridCell(imageURLs: files)
                    case .text(let message):
                        MessageView(message: message)
                    }
                }
                Text(message.createdAt.toTimeString())
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.gray)
                    .opacity(showTime ? 1 : 0)
            }
        }
    }
}

private struct MessageView: View {
    let message: String
    var body: some View {
        Text(message)
            .font(.system(size: 13, weight: .regular))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .lineSpacing(4)
            .background(Color(uiColor: .systemGray5))
            .foregroundColor(.black)
            .cornerRadius(16)
    }
}


private struct MessageMeView: View {
    let message: String
    var body: some View {
        Text(message)
            .font(.system(size: 13, weight: .regular))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .lineSpacing(4)
            .background(.juhwang)
            .foregroundColor(.white)
            .cornerRadius(16)
    }
}
