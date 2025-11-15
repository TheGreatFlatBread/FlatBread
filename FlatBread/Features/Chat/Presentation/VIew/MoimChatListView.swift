//
//  MoimChatListView.swift
//  FlatBread
//
//  Created by hwan on 11/12/25.
//

import SwiftUI

struct MoimChatListView: View {
    @StateObject private var viewModel = MoimChatListViewModel()
    
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
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(participantName.prefix(1))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(participantName)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)

                    Spacer()
                    
                    Text(room.lastChat?.createdAt.relativeTime() ?? "")
                        .font(.system(size: 11, weight: .thin))
                        .foregroundColor(.gray)
                }

                Text(room.lastChat?.messegeType.getLastMessage() ?? "")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        MoimChatListView()
    }
}
