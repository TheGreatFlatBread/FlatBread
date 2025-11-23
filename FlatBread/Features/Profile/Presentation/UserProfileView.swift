//
//  UserProfileView.swift
//  FlatBread
//
//  Created by hwan on 11/21/25.
//

import SwiftUI

struct UserProfileView: View {

    @StateObject private var viewModel: UserProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showEditProfile = false
    @State private var chatRoomToNavigate: ChatRoomModel?
    @State private var showChatRoom = false

    init(userID: String, moimId: String? = nil, isCurrentUser: Bool = false) {
        _viewModel = StateObject(wrappedValue: UserProfileViewModel(
            userID: userID,
            moimId: moimId,
            isCurrentUser: isCurrentUser
        ))
    }

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if let profile = viewModel.userProfile {
                VStack(spacing: 24) {
                    profileHeader(profile: profile)
                    if viewModel.moimId != nil {
                        userPostsSection
                    }
                }
                .padding()
            } else {
                ContentUnavailableView(
                    "프로필을 불러올 수 없습니다",
                    systemImage: "person.slash",
                    description: Text(viewModel.errorMessage ?? "")
                )
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.isCurrentUser ? "내 프로필" : "프로필")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isCurrentUser {
                    Button {
                        showEditProfile = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(.orange)
                    }
                } else {
                    Button {
                        Task {
                            if let room = await viewModel.startChat() {
                                chatRoomToNavigate = room
                                showChatRoom = true
                            }
                        }
                    } label: {
                        if viewModel.isCreatingChat {
                            ProgressView()
                                .tint(.orange)
                        } else {
                            Image(systemName: "message.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                    .disabled(viewModel.isCreatingChat)
                }
            }
        }
        .navigationDestination(isPresented: $showChatRoom) {
            if let room = chatRoomToNavigate {
                ChatRoomView(room: room, currentUserID: viewModel.currentUserId)
            }
        }
        .sheet(isPresented: $showEditProfile) {
            if let profile = viewModel.userProfile {
                EditProfileView(userProfile: profile)
            }
        }
        .task {
            await viewModel.fetchCurrentUserId()
            await viewModel.fetchUserProfile()
            await viewModel.fetchUserPosts()
        }
        .alert("오류", isPresented: $viewModel.showingAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "알 수 없는 오류가 발생했습니다")
        }
    }

    private func profileHeader(profile: UserProfileResponseDTO) -> some View {
        VStack(spacing: 16) {
            profileImageView(imageURL: profile.profileImage)

            Text(profile.nick ?? "이름 없음")
                .font(.title2)
                .fontWeight(.bold)

            if let info = profile.info1, !info.isEmpty {
                Text(info)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 32) {
                statItem(count: profile.followers.count, title: "팔로워")
                statItem(count: profile.following.count, title: "팔로잉")
                statItem(count: profile.postIDList.count, title: "게시물")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
    }

    private func profileImageView(imageURL: String?) -> some View {
        Group {
            if let urlString = imageURL, !urlString.isEmpty {
                RemoteImage(url: urlString, displayMode: .thumbnail(CGSize(width: 120, height: 120))) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundStyle(.gray)
                } content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(.gray)
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 1))
    }

    private func statItem(count: Int, title: String) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.headline)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func profileInfoSection(profile: UserProfileResponseDTO) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("정보")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                if let gender = profile.gender {
                    infoRow(icon: "person.fill", title: "성별", value: gender == "male" ? "남성" : "여성")
                    Divider().padding(.leading, 44)
                }

                if let birthday = profile.birthDay {
                    infoRow(icon: "calendar", title: "생년월일", value: birthday)
                    Divider().padding(.leading, 44)
                }

                if let email = profile.email {
                    infoRow(icon: "envelope.fill", title: "이메일", value: email, isLast: true)
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }

    private func infoRow(icon: String, title: String, value: String, isLast: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.secondary)

            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)

            Text(value)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var userPostsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("모임 내 게시물")
                    .font(.headline)
                Text("\(viewModel.userPosts.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 4)

            if viewModel.isLoadingPosts {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if viewModel.userPosts.isEmpty {
                emptyPostsView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.userPosts, id: \.id) { post in
                        UserPostCard(post: post)
                    }

                    if viewModel.hasMorePosts {
                        if viewModel.isLoadingMorePosts {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        } else {
                            Button {
                                Task {
                                    await viewModel.loadMorePosts()
                                }
                            } label: {
                                HStack {
                                    Text("더 보기")
                                    Image(systemName: "chevron.down")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyPostsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 36))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("작성한 게시물이 없습니다")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - User Post Card
extension UserProfileView {
    struct UserPostCard: View {
        let post: PostUIModel

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(post.postType.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)

                    Spacer()

                    Text(post.createdAt.relativeTimeString())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(post.content)
                    .font(.subheadline)
                    .lineLimit(3)
                    .foregroundStyle(.primary)

                if !post.images.isEmpty {
                    RemoteImage(
                        url: post.images.first ?? "",
                        displayMode: .thumbnail(CGSize(width: 300, height: 120))
                    ) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    }
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(8)
                    .clipped()
                }

                HStack(spacing: 16) {
                    Label("\(post.likeCount)", systemImage: "heart")
                    Label("\(post.commentCount)", systemImage: "bubble.right")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

//#Preview {
//    NavigationStack {
//        OtherUserProfileView(userID: "preview_user_id")
//    }
//}
