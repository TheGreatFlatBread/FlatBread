//
//  MoimChatListView.swift
//  FlatBread
//
//  Created by hwan on 11/12/25.
//

import SwiftUI

struct MoimChatListView: View {
    @StateObject private var viewModel = MoimChatListViewModel()
    let currentUserID: String

    @State private var selectedRoom: ChatRoomModel?
    @State private var showChatRoom = false

    init(currentUserID: String) {
        self.currentUserID = currentUserID
    }

    var body: some View {
        List(viewModel.chatRooms, id: \.id) { room in
            ChatListRowView(room: room, currentUserID: currentUserID)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedRoom = room
                    showChatRoom = true
                }
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationTitle("채팅")
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(isPresented: $showChatRoom) {
            if let room = selectedRoom {
                ChatRoomView(room: room, currentUserID: currentUserID)
            }
        }
        .task {
            await viewModel.loadChatRooms()
        }
    }
}

private struct ChatListRowView: View {
    let room: ChatRoomModel
    let currentUserID: String

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
        HStack(spacing: 12) {
            if let imageURL = profileImageURL, !imageURL.isEmpty {
                ProfileImage(profileImageURL: imageURL)
                    .frame(width: 50, height: 50)
            } else {
                DefaultProfile(prefix: String(participantName.prefix(1)))
            }

            UserDescription(
                participantName: participantName,
                createdAt: room.lastChat?.createdAt.relativeTime() ?? "",
                lastMessage: room.lastChat?.messegeType.getLastMessage() ?? ""
            )
        }
        .padding(.vertical, 4)
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
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(participantName)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)

                Spacer()
                
                Text(createdAt)
                    .font(.system(size: 11, weight: .thin))
                    .foregroundColor(.gray)
            }

            Text(lastMessage)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
    }
}

#Preview {
    NavigationStack {
        MoimChatListView(currentUserID: "preview_user")
    }
}
