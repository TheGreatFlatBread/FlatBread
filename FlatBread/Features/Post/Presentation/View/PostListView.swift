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
    @State private var isSelectedTab: MoimTab = .posts
    @State private var isSelectedSchedule: ScheduleUIModel?
    
    init(moim: TempPostMoimModel) {
        _viewModel = StateObject(wrappedValue: PostListViewModel(moim: moim))
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                if let moim = viewModel.moim {
                    ScrollView {
                        VStack(spacing: 16) {
                            PostListView.MoimHeader(moim: moim)
                            
                            PostListView.CategoryAndTabSection(
                                selectedTab: $isSelectedTab,
                                selectedCategory: $viewModel.selectedCategory,
                                postCount: viewModel.posts.count
                            )
                            
                            switch isSelectedTab {
                            case .schedule:
                                PostListView.ScheduleListView(
                                    schedules: viewModel.schedules,
                                    selectedSchedule: $isSelectedSchedule
                                )
                            case .posts:
                                PostListView.PostList(
                                    posts: viewModel.filteredPosts,
                                    onLikeTap: viewModel.toggleLike(for:),
                                    onCommentTap: { comment in  },
                                    settingTapped: { _ in }
                                )
                            case .members:
                                PostListView.MembersListView(
                                    members: viewModel.members,
                                    cellTapped: { _ in }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                    }
                    .background(Color(.systemGroupedBackground))
                    
                    FloatingWriteButton(showWriteView: $isShowWriteView)
                } else {
                    ProgressView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolBarItem
            }
        }
        .sheet(isPresented: $isShowWriteView) {
            // PostWriteView(moimId: viewModel.moimId)
            //     .interactiveDismissDisabled()
        }
        .sheet(item: $isSelectedSchedule) { schedule in
            // ScheduleDetailView(schedule: schedule)
        }
    }
    
    @ToolbarContentBuilder
    var toolBarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                // TODO: Dismiss
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
            }
        }
        
        ToolbarItem(placement: .principal) {
            Text(viewModel.moim?.name ?? "")
                .font(.system(size: 17, weight: .semibold))
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 16) {
                Button {
                    // TODO: Search
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                
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
        
        var body: some View {
            VStack(spacing: 0) {
                AsyncImage(url: URL(string: moim.imageURLs.first ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundStyle(.white.opacity(0.5))
                        }
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
                                Text("\(moim.memberCount)명")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(16)
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    struct CategoryAndTabSection: View {
        @Binding var selectedTab: MoimTab
        @Binding var selectedCategory: PostType
        let postCount: Int

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
                                        selectedCategory = category
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
            LazyVStack(spacing: 12) {
                ForEach(schedules) { schedule in
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
    
    struct PostList: View {
        let posts: [PostUIModel]
        let onLikeTap: (PostUIModel) -> Void
        let onCommentTap: (PostUIModel) -> Void
        let settingTapped: (PostUIModel) -> Void
        
        var body: some View {
            LazyVStack(spacing: 12) {
                ForEach(posts) { post in
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
        let cellTapped: (MemberUIModel) -> Void
        
        var body: some View {
            LazyVStack(spacing: 12) {
                ForEach(members) { member in
                    MemberCardView(member: member) {
                        cellTapped(member)
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                }
            }
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
