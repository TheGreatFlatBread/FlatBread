//
//  PostListView.swift
//  FlatBread
//
//  Created by hwan on 11/16/25.
//

import SwiftUI

extension PostListView {
    enum ActiveSheet: Identifiable {
        case writePost
        case schedule(ScheduleUIModel)
        case editPost(PostUIModel)

        var id: String {
            switch self {
            case .writePost: return "writePost"
            case .schedule(let s): return "schedule_\(s.id)"
            case .editPost(let p): return "editPost_\(p.id)"
            }
        }
    }

    enum ActiveDialog: Identifiable {
        case postOptions(PostUIModel)
        case deleteConfirmation(PostUIModel)

        var id: String {
            switch self {
            case .postOptions(let p): return "options_\(p.id)"
            case .deleteConfirmation(let p): return "delete_\(p.id)"
            }
        }

        var post: PostUIModel {
            switch self {
            case .postOptions(let p), .deleteConfirmation(let p):
                return p
            }
        }
    }

    enum NavigationDestination: Hashable {
        case postDetail(PostUIModel)
        case myProfile
        case otherProfile(userID: String, moimId: String)
    }
}

struct PostListView: View {
    @StateObject private var viewModel: PostListViewModel

    @State private var activeSheet: ActiveSheet?
    @State private var showPaymentSheet: Bool = false
    @State private var paymentInput: IamportPaymentInput?
    @State private var activeDialog: ActiveDialog?
    @State private var activeNavigation: NavigationDestination?

    init(moim: TempPostMoimModel) {
        _viewModel = StateObject(wrappedValue: PostListViewModel(moim: moim))
    }
    
    init(moimId: String) {
        _viewModel = StateObject(wrappedValue: PostListViewModel(moimId: moimId))
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
                                // 결제 필요 여부 확인
                                if let input = viewModel.makePaymentInputForMoimJoin(), input.price > 0 {
                                    DispatchQueue.main.async {
                                        self.paymentInput = input
                                        // paymentInput 세팅 이후 시트를 올려 순서 보장
                                        self.showPaymentSheet = true
                                    }
                                } else {
                                    Task {
                                        await viewModel.toggleMoimMembership()
                                    }
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
                                    onScheduleTap: { schedule in
                                        activeSheet = .schedule(schedule)
                                    }
                                )
                            case .posts:
                                PostListView.PostList(
                                    posts: viewModel.filteredPosts,
                                    onLikeTap: viewModel.toggleLike(for:),
                                    onCommentTap: { post in
                                        activeNavigation = .postDetail(post)
                                    },
                                    settingTapped: { post in
                                        activeDialog = .postOptions(post)
                                    }
                                )
                            case .members:
                                PostListView.MembersListView(
                                    members: viewModel.members,
                                    currentUserId: viewModel.currentUserId,
                                    cellTapped: { member in
                                        if member.id == viewModel.currentUserId {
                                            activeNavigation = .myProfile
                                        } else {
                                            activeNavigation = .otherProfile(userID: member.id, moimId: viewModel.moimId)
                                        }
                                    }
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
                    FloatingWriteButton {
                        activeSheet = .writePost
                    }
                }
            } else {
                if viewModel.isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.errorMessage != nil {
                    ContentUnavailableView(
                        "모임을 불러올 수 없습니다",
                        systemImage: "exclamationmark.triangle",
                        description: Text(viewModel.errorMessage ?? "")
                    )
                } else {
                    ContentUnavailableView(
                        "모임 정보가 없습니다",
                        systemImage: "person.3.fill",
                        description: Text("잠시 후 다시 시도해주세요")
                    )
                }
            }
        }
        .toolbarRole(.editor)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            toolBarItem
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $activeNavigation) { destination in
            switch destination {
            case .postDetail(let post):
                PostDetailView(postId: post.id, currentUserId: viewModel.currentUserId)
                    .environmentObject(viewModel)
            case .myProfile:
                UserProfileView(userID: viewModel.currentUserId, moimId: viewModel.moimId, isCurrentUser: true)
            case .otherProfile(let userID, let moimId):
                UserProfileView(userID: userID, moimId: moimId, isCurrentUser: false)
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .writePost:
                PostWriteView(
                    moimId: viewModel.moimId,
                    onPostCreated: { response in
                        viewModel.addNewPost(response)
                    }
                )
                .interactiveDismissDisabled()
            case .schedule(let schedule):
                ScheduleDetailView(schedule: schedule)
            case .editPost(let post):
                PostPatchView(
                    post: post,
                    onPostUpdated: { response in
                        viewModel.updateExistingPost(response)
                    }
                )
            }
        }
        .sheet(isPresented: Binding(
            get: { showPaymentSheet && paymentInput != nil },
            set: { newValue in
                if !newValue {
                    showPaymentSheet = false
                    paymentInput = nil
                }
            }
        )) {
            PaymentSheetView(input: paymentInput!)
        }
        .confirmationDialog(
            "게시물 옵션",
            isPresented: Binding(
                get: {
                    if case .postOptions = activeDialog { return true }
                    return false
                },
                set: { if !$0 { activeDialog = nil } }
            ),
            presenting: activeDialog?.post
        ) { post in
            if viewModel.isMyPost(post) {
                Button("수정") {
                    activeDialog = nil
                    activeSheet = .editPost(post)
                }
                Button("삭제", role: .destructive) {
                    activeDialog = .deleteConfirmation(post)
                }
            }
        }
        .alert(
            "게시물을 삭제하시겠습니까?",
            isPresented: Binding(
                get: {
                    if case .deleteConfirmation = activeDialog { return true }
                    return false
                },
                set: { if !$0 { activeDialog = nil } }
            )
        ) {
            Button("취소", role: .cancel) {
                activeDialog = nil
            }
            Button("삭제", role: .destructive) {
                if let post = activeDialog?.post {
                    Task {
                        _ = await viewModel.deletePost(post.id)
                        activeDialog = nil
                    }
                }
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
        let onScheduleTap: (ScheduleUIModel) -> Void

        var body: some View {
            if schedules.isEmpty {
                EmptyScheduleView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(schedules, id: \.id) { schedule in
                        ScheduleCardView(schedule: schedule) {
                            onScheduleTap(schedule)
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
        let onLikeTap:  @MainActor (PostUIModel) async -> Void
        let onCommentTap: (PostUIModel) -> Void
        let settingTapped: (PostUIModel) -> Void

        var body: some View {
            if posts.isEmpty {
                EmptyPostView()
            } else {
                ForEach(posts, id: \.id) { post in
                    PostCardView(
                        post: post,
                        onLikeTap: {
                            Task { await onLikeTap(post) }
                        },
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
        let action: () -> Void

        var body: some View {
            Button(action: action) {
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

private struct PaymentSheetView: View {
    let input: IamportPaymentInput
    var body: some View {
        IamportPaymentView(input: input)
    }
}

#Preview {
    PostListView(moim: .mock)
}
