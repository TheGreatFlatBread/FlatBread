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
        NavigationStack {
            List(viewModel.chatRooms, id: \.id) { room in
                NavigationLink(value: room) {
                    ChatListRowView(room: room)
                }
                .listRowSeparator(.hidden)
                .tint(Color.blue)
            }
            .tint(Color.blue)
            .listStyle(.plain)
            .navigationTitle("채팅")
            .navigationDestination(for: ChatRoomModel.self) { room in
                ChatRoomView(room: room, currentUserID: "current_user_id")
            }
        }
        .tint(.black)
    }
}

private struct ChatListRowView: View {
    let room: ChatRoomModel

    private var participantName: String {
        room.participants.first?.nick ?? "Unknown"
    }

    private var profileURL: URL? {
        guard let path = room.participants.first?.profileImage else { return nil }
        return URL(string: "https://your.api.host\(path)")
    }

    var body: some View {
        HStack(spacing: 12) {
            if let profileImageURL = room.participants.first?.profileImage, !profileImageURL.isEmpty {
                ProfileImage(profileImageURL: profileImageURL)
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
            url: "https://i.pravatar.cc/150?img=\(abs(profileImageURL.hashValue % 70))",
            displayMode: .thumbnail(CGSize(width: 100, height: 100))
        ) { image in
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
