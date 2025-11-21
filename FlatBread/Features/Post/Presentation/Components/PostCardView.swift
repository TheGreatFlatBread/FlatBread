//
//  PostCardView.swift
//  FlatBread
//
//  Created by hwan on 11/16/25.
//

import SwiftUI

struct PostCardView: View {
    let post: PostUIModel
    let onLikeTap: () -> Void
    let onCommentTap: () -> Void
    let settingTapped: () -> Void

    @State private var isExpanded = false
    @State private var currentImageIndex = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PostSectionHeader(
                authorName: post.author.name,
                profileImageURL: post.author.profileImageURL ?? "",
                relativeTime: post.createdAt.relativeTimeString(), 
                settingTapped: settingTapped
            )

            if !post.images.isEmpty {
                ZStack(alignment: .bottom) {
                    TabView(selection: $currentImageIndex) {
                        ForEach(Array(post.images.enumerated()), id: \.element) { index, imageURL in
                            RemoteImage(
                                url: imageURL,
                                displayMode: .thumbnail(CGSize(width: 400, height: 300))
                            ) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .clipped()
                            .tag(index)
                        }
                    }
                    .frame(height: 300)
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    if post.images.count > 1 {
                        HStack(spacing: 6) {
                            ForEach(0..<post.images.count, id: \.self) { index in
                                Circle()
                                    .fill(currentImageIndex == index ? Color.white : Color.white.opacity(0.5))
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Capsule())
                        .padding(.bottom, 12)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                ContentBody(
                    content: post.content,
                    isExpanded: $isExpanded
                )

                if let schedule = post.schedule {
                    ScheduleComponent(
                        scheduleTitle: schedule.title,
                        scheduleParticipantCount: schedule.participantCount,
                        maxParticipants: schedule.maxParticipants
                    )
                }

                LikeAndCommentComponent(
                    isLiked: post.isLiked,
                    likeCount: post.likeCount,
                    commentCount: post.commentCount,
                    onLikeTap: onLikeTap,
                    onCommentTap: onCommentTap
                )
            }
            .padding(16)
        }
    }
}

extension PostCardView {
    struct PostSectionHeader: View {
        let authorName: String
        let profileImageURL: String
        let relativeTime: String
        let settingTapped: () -> Void
        
        var body: some View {
            HStack(spacing: 10) {
                
                PostProfileImage(profileImageURL: profileImageURL)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(authorName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(relativeTime)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    settingTapped()
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    struct ContentBody: View {
        let content: String
        @Binding var isExpanded: Bool
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(content)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                    .lineLimit(isExpanded ? nil : 3)
                    .fixedSize(horizontal: false, vertical: true)

                if content.count > 100 && !isExpanded {
                    Button {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    } label: {
                        Text("더보기")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    struct ScheduleComponent: View {
        let scheduleTitle: String
        let scheduleParticipantCount: Int
        let maxParticipants: Int
        
        var body: some View {
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(scheduleTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text("\(scheduleParticipantCount)/\(maxParticipants)명 참여")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    struct LikeAndCommentComponent: View {
        let isLiked: Bool
        let likeCount: Int
        let commentCount: Int
        
        let onLikeTap: () -> Void
        let onCommentTap: () -> Void
        
        var body: some View {
            HStack(spacing: 16) {
                Button {
                    onLikeTap()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(isLiked ? .red : .primary)

                        if likeCount > 0 {
                            Text("\(likeCount)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.primary)
                        }
                    }
                }

                Button {
                    onCommentTap()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(.primary)

                        if commentCount > 0 {
                            Text("\(commentCount)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.primary)
                        }
                    }
                }

                Spacer()
            }
        }
    }
}

#Preview {
    VStack {
        PostCardView(
            post: PostUIModel.mock,
            onLikeTap: {},
            onCommentTap: {},
            settingTapped: {}
        )

        Divider()

        PostCardView(
            post: PostUIModel.mock,
            onLikeTap: {},
            onCommentTap: {},
            settingTapped: {}
        )
    }
}
