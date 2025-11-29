//
//  MoimChatListView.swift
//  FlatBread
//
//  Created by hwan on 11/12/25.
//

import SwiftUI

struct MoimChatListView: View {
    @StateObject private var viewModel: MoimChatListViewModel
    let currentUserID: String

    @State private var selectedRoom: ChatRoomModel?
    @State private var showChatRoom = false

    init(currentUserID: String) {
        self.currentUserID = currentUserID
        _viewModel = StateObject(wrappedValue: MoimChatListViewModel(currentUserID: currentUserID))
    }

    var body: some View {
        List(viewModel.chatRooms, id: \.id) { room in
            VStack(spacing: 0) {
                ChatListRowView(room: room, currentUserID: currentUserID)
                    .equatable()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedRoom = room
                        showChatRoom = true
                    }
                Divider()
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationTitle("채팅")
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(isPresented: $showChatRoom) {
            if let selectedRoom {
                ChatRoomView(room: selectedRoom, currentUserID: currentUserID)
            }
        }
        .task {
            await viewModel.loadChatRooms()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard !Task.isCancelled else { break }
                await viewModel.loadChatRooms()
            }
        }
    }
}

private struct ChatListRowView: View, Equatable {
    let room: ChatRoomModel
    let currentUserID: String

    static func == (lhs: ChatListRowView, rhs: ChatListRowView) -> Bool {
        lhs.room.id == rhs.room.id &&
        lhs.room.lastChat?.id == rhs.room.lastChat?.id &&
        lhs.room.unreadCount == rhs.room.unreadCount &&
        lhs.currentUserID == rhs.currentUserID
    }

    private var opponent: ChatUserModel? {
        room.participants.first { $0.id != currentUserID }
    }

    private var participantName: String {
        opponent?.nick ?? "Unknown"
    }

    private var profileImageURL: String? {
        opponent?.profileImage
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let imageURL = profileImageURL, !imageURL.isEmpty {
                ProfileImage(profileImageURL: imageURL)
                    .frame(width: 50, height: 50)
            } else {
                DefaultProfile(prefix: String(participantName.prefix(1)))
            }

            UserDescription(
                participantName: participantName,
                createdAt: room.lastChat?.createdAt.relativeTime() ?? "",
                lastMessage: room.lastChat?.messegeType.getLastMessage() ?? "",
                unreadCount: room.unreadCount
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct ProfileImage: View {
    let profileImageURL: String
    var body: some View {
        RemoteImage(
            url: profileImageURL,
            displayMode: .thumbnail(CGSize(width: 100, height: 100))
        ) {
            // placeholder
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
        } content: { image in
            image
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.33)
                )
        }
    }
}

private struct DefaultProfile: View {
    let prefix: String
    
    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 50, height: 50)
            .overlay(
                Text(prefix)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            )
    }
}

private struct UserDescription: View {
    let participantName: String
    let createdAt: String
    let lastMessage: String
    let unreadCount: Int

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // 왼쪽: 닉네임 + 메시지
            VStack(alignment: .leading, spacing: 4) {
                Text(participantName)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)

                Text(lastMessage)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // 오른쪽: 시간 + Badge
            VStack(alignment: .trailing, spacing: 4) {
                Text(createdAt)
                    .font(.system(size: 11, weight: .thin))
                    .foregroundColor(.gray)

                if unreadCount > 0 {
                    Text("\(unreadCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MoimChatListView(currentUserID: "preview_user")
    }
}
