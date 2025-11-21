//
//  MemberCardView.swift
//  FlatBread
//
//  Created by hwan on 11/16/25.
//

import SwiftUI

struct MemberCardView: View {
    let member: MemberUIModel
    let currentUserId: String?
    let cellTapped: () -> Void

    private var isMe: Bool {
        guard let currentUserId else { return false }
        return member.id == currentUserId
    }

    var body: some View {
        Button(action: cellTapped) {
            HStack(spacing: 14) {
                PostProfileImage(profileImageURL: member.profileImageURL ?? "")

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(member.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)

                        if member.isLeader {
                            Text("모임장")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.orange.opacity(0.1))
                                .clipShape(Capsule())
                        }

                        if isMe {
                            Text("나")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }

                    if let bio = member.bio {
                        Text(bio)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    VStack(spacing: 12) {
        ForEach(MemberUIModel.mocks) { member in
            MemberCardView(member: member, currentUserId: MemberUIModel.mocks.first?.id) {
                print("Tapped: \(member.name)")
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
