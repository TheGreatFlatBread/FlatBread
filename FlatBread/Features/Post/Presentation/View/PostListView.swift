//
//  PostListView.swift
//  FlatBread
//
//  Created by hwan on 11/16/25.
//

import SwiftUI

struct PostListView: View {
    @StateObject private var viewModel: PostListViewModel
    @State private var isShowWriteView = false
    @State private var isSelectedSchedule: ScheduleUIModel?
    @State private var selectedPostForComment: PostUIModel?
    
    @State private var showOptions = false
    @State private var selectedPostForOptions: PostUIModel?
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false
    
    init(moim: TempPostMoimModel) {
        _viewModel = StateObject(wrappedValue: PostListViewModel(moim: moim))
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let moim = viewModel.moim {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        PostListView.MoimHeader(
                            moim: moim,
                            isLeader: viewModel.isLeader,
                            isMember: viewModel.isMember,
                            onJoinTap: {
                                Task {
                                    await viewModel.toggleMoimMembership()
                                }
                            }
                        )
                        
                        PostListView.CategoryAndTabSection(
                            selectedTab: $viewModel.selectedTab,
                            selectedCategory: viewModel.selectedCategory,
                            postCount: viewModel.posts.count,
                            onCategorySelect: { category in
                                viewModel.selectCategory(category)
                            }
                        )
                        
                        if viewModel.isLeader || viewModel.isMember {
                            switch viewModel.selectedTab {
                            case .schedule:
                                PostListView.ScheduleListView(
                                    schedules: viewModel.schedules,
                                    selectedSchedule: $isSelectedSchedule
                                )
                            case .posts:
                                PostListView.PostList(
                                    posts: viewModel.filteredPosts,
                                    onLikeTap: viewModel.toggleLike(for:),
                                    onCommentTap: { post in
                                        selectedPostForComment = post
                                    },
                                    settingTapped: { post in
                                        showOptions = true
                                        selectedPostForOptions = post
                                    }
                                )
                            case .members:
                                PostListView.MembersListView(
                                    members: viewModel.members,
                                    currentUserId: viewModel.currentUserId,
                                    cellTapped: { _ in }
                                )
                            }
                        } else {
                            switch viewModel.selectedTab {
                            case .schedule:
                                PostListView.MemberOnlyView(tabName: "일정")
                            case .posts:
                                PostListView.MemberOnlyView(tabName: "게시물")
                            case .members:
                                PostListView.MemberOnlyView(tabName: "멤버")
                            }
                        }
                        
                        if viewModel.shouldShowPagination {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .onAppear {
                                        Task {
                                            await viewModel.loadMore()
                                        }
                                    }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
                .background(Color(.systemGroupedBackground))
                
                if viewModel.isMember || viewModel.isLeader {
                    FloatingWriteButton(showWriteView: $isShowWriteView)
                }
            } else {
                ProgressView()
            }
        }
        .toolbarRole(.editor)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            toolBarItem
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedPostForComment) { post in
            PostDetailView(postId: post.id, currentUserId: viewModel.currentUserId)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $isShowWriteView) {
            PostWriteView(
                moimId: viewModel.moimId,
                onPostCreated: { response in
                    viewModel.addNewPost(response)
                }
            )
            .interactiveDismissDisabled()
        }
        .sheet(item: $isSelectedSchedule) { schedule in
             ScheduleDetailView(schedule: schedule)
        }
        .confirmationDialog(
            "게시물 옵션",
            isPresented: $showOptions,
            presenting: selectedPostForOptions
        ) { post in
            if viewModel.isMyPost(post) {
                Button("수정") {
                    showEditSheet = true
                }
                Button("삭제", role: .destructive) {
                    showDeleteConfirmation = true
                }
            } else {
                // Button("신고", role: .destructive) { }
            }
        }
        .alert("게시물을 삭제하시겠습니까?", isPresented: $showDeleteConfirmation) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                if let post = selectedPostForOptions {
                    Task {
                        let success = await viewModel.deletePost(post.id)
                        if success {
                            selectedPostForOptions = nil
                        } else {
                            selectedPostForOptions = nil
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showEditSheet) {
            if let post = selectedPostForOptions {
                PostPatchView(
                    post: post,
                    onPostUpdated: { response in
                        viewModel.updateExistingPost(response)
                    }
                )
            }
        }
        .task {
            await viewModel.loadInitialData()
        }
    }
    
    @ToolbarContentBuilder
    var toolBarItem: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(viewModel.moim?.name ?? "")
                .font(.system(size: 17, weight: .semibold))
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 16) {
                Button {
                    // TODO: Setting View
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                }
            }
        }
    }
}

extension PostListView {
    struct MoimHeader: View {
        let moim: TempPostMoimModel
        let isLeader: Bool
        let isMember: Bool
        let onJoinTap: () -> Void
        
        var body: some View {
            VStack(spacing: 0) {
                RemoteImage(
                    url: moim.imageURLs.first ?? "",
                    displayMode: .thumbnail(CGSize(width: 400, height: 180))
                ) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipped()
                
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(moim.name)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.primary)
                            
                            HStack(spacing: 6) {
                                if let location = moim.location {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                    Text(location.name)
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                    
                                    Text("·")
                                        .foregroundStyle(.secondary)
                                }
                                
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                Text("\(moim.memberCount + 1)명")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    
                    if !isLeader {
                        Button(action: onJoinTap) {
                            HStack {
                                Image(systemName: isMember ? "person.badge.minus" : "person.badge.plus")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(isMember ? "탈퇴하기" : "가입하기")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(isMember ? .red : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isMember ? Color.red.opacity(0.1) : Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    struct CategoryAndTabSection: View {
        @Binding var selectedTab: MoimTab
        let selectedCategory: PostType
        let postCount: Int
        let onCategorySelect: (PostType) -> Void
        
        var body: some View {
            VStack(spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MoimTab.allCases, id: \.self) { tab in
                            TabChip(
                                title: tab.title,
                                icon: tab.icon,
                                isSelected: selectedTab == tab
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = tab
                                }
                            }
                        }
                    }
                }
                
                if selectedTab == .posts {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(PostType.allCases, id: \.self) { category in
                                CategoryChip(
                                    title: category.displayName,
                                    count: category == .all ? postCount : nil,
                                    isSelected: selectedCategory == category
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        onCategorySelect(category)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    struct ScheduleListView: View {
        let schedules: [ScheduleUIModel]
        @Binding var selectedSchedule: ScheduleUIModel?
        
        var body: some View {
            if schedules.isEmpty {
                EmptyScheduleView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(schedules, id: \.id) { schedule in
                        ScheduleCardView(schedule: schedule) {
                            selectedSchedule = schedule
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    }
                }
            }
        }
    }
    
    struct PostList: View {
        let posts: [PostUIModel]
        let onLikeTap: (PostUIModel) -> Void
        let onCommentTap: (PostUIModel) -> Void
        let settingTapped: (PostUIModel) -> Void
        
        var body: some View {
            if posts.isEmpty {
                EmptyPostView()
            } else {
                ForEach(posts, id: \.id) { post in
                    PostCardView(
                        post: post,
                        onLikeTap: { onLikeTap(post) },
                        onCommentTap: { onCommentTap(post) },
                        settingTapped: { settingTapped(post) }
                    )
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                }
            }
        }
    }
    
    struct MembersListView: View {
        let members: [MemberUIModel]
        let currentUserId: String
        let cellTapped: (MemberUIModel) -> Void

        var body: some View {
            if members.isEmpty {
                EmptyMembersView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(members, id: \.id) { member in
                        MemberCardView(member: member, currentUserId: currentUserId) {
                            cellTapped(member)
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    }
                }
            }
        }
    }
    
    struct EmptyPostView: View {
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "doc.text")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary.opacity(0.3))
                Text("아직 게시물이 없습니다")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                Text("첫 게시물을 작성해보세요")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
    }
    
    struct EmptyScheduleView: View {
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "calendar")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary.opacity(0.3))
                Text("등록된 일정이 없습니다")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                Text("새로운 일정을 만들어보세요")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
    }
    
    struct EmptyMembersView: View {
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "person.2")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary.opacity(0.3))
                Text("아직 멤버가 없습니다")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
    }
    
    struct MemberOnlyView: View {
        let tabName: String
        
        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange.opacity(0.5))
                
                VStack(spacing: 8) {
                    Text("\(tabName)은 멤버만 볼 수 있습니다")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text("모임에 가입하고 \(tabName)을 확인해보세요")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 80)
        }
    }
    
    struct FloatingWriteButton: View {
        @Binding var showWriteView: Bool
        
        var body: some View {
            Button {
                showWriteView = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.orange.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: Color.orange.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
    }
    
    struct TabChip: View {
        let title: String
        let icon: String
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    isSelected ? Color.orange : Color(.systemBackground)
                )
                .clipShape(Capsule())
                .shadow(color: .black.opacity(isSelected ? 0.1 : 0.05), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    struct CategoryChip: View {
        let title: String
        let count: Int?
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    if let count {
                        Text("\(count)")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .foregroundStyle(isSelected ? .white : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected
                    ? Color.orange.opacity(0.9)
                    : Color(.systemGray5)
                )
                .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    PostListView(moim: .mock)
}
