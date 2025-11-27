//
//  ProfileView.swift
//  FlatBread
//
//  Created by 김민성 on 11/13/25.
//

import Combine
import SwiftUI

struct ProfileView: View {
    
    @StateObject private var viewModel: ProfileViewModel
    
    init(viewModel: ProfileViewModel = ProfileViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack(path: $viewModel.path) {
            ScrollView {
                VStack(spacing: 24) {
                    profileInfoSection(profile: viewModel.myProfile)
                    menuSection
                }
                .padding()
            }
            .navigationTitle("내 프로필")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .navigationDestination(for: NavigationRoute.self) { route in
                switch route {
                case .profile:
                    EditProfileView(userProfile: viewModel.myProfile)
                case .myMoim:
                    DummyView(navigationTitle: "내가 만든 모임", text: "내 모임")
                case .makeNewMoim:
                    DummyView(navigationTitle: "새 모임 만들기", text: "새 모임")
                case .chatList:
                    MoimChatListView(currentUserID: viewModel.myProfile?.userID ?? "")
                case .withdraw:
                    // 탈퇴 기능은 추후 alert로 대체
                    DummyView(navigationTitle: "탈퇴하기", text: "탈퇴")
                }
            }
        }
        .tint(.primary)
        .task {
            await viewModel.requestMyProfile()
        }
        .alert(
            viewModel.alertTitle,
            isPresented: $viewModel.showingAlert) {
                Button("확인", role: .cancel) { return }
            } message: {
                Text(viewModel.alertMessage)
            }

    }
    
    // MARK: - 프로필 정보 섹션
    private func profileInfoSection(profile: UserProfileResponseDTO?) -> some View {
        VStack(spacing: 16) {
            if viewModel.isLoadingProfile {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(height: 60)
            } else {
                HStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .foregroundColor(.gray)
                    
                    Text(profile?.nick ?? "닉네임 없음")
                        .font(.system(size: 20, weight: .bold))
                    
                    Spacer()
                }
            }

            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                profileInfoRow(
                    systemImage: "envelope.fill",
                    title: "이메일",
                    value: profile?.email
                )
                profileInfoRow(
                    systemImage: "calendar",
                    title: "생년월일",
                    value: profile?.birthDay
                )
                profileInfoRow(
                    systemImage: "person.fill",
                    title: "성별",
                    value: {
                        guard let gender = profile?.gender else { return nil }
                        return (gender == "male") ? "남성" : "여성"
                    }()
                )
                profileInfoRow(
                    systemImage: "phone.fill",
                    title: "전화번호",
                    value: profile?.phoneNum
                )
            }
            
            NavigationLink(value: NavigationRoute.profile) {
                HStack {
                    Spacer()
                    Text("수정")
                        .foregroundStyle(.white)
                        .frame(height: 40, alignment: .center)
                    Spacer()
                }
                .background(.orange)
                .cornerRadius(14)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.myProfile == nil)
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(32)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - 메뉴 버튼 섹션
    private var menuSection: some View {
        VStack(spacing: 12) {
            VStack(spacing: 0) {
                NavigationLink(value: NavigationRoute.myMoim) {
                    ProfileMenuButtonRow(title: "내가 만든 모임 확인하기")
                }
                
                NavigationLink(value: NavigationRoute.makeNewMoim) {
                    ProfileMenuButtonRow(title: "새 모임 만들기")
                }
                
                NavigationLink(value: NavigationRoute.chatList) {
                    ProfileMenuButtonRow(title: "채팅 목록")
                }
            }
            .padding(10)
            .background(.white)
            .cornerRadius(32)
            
            NavigationLink(value: NavigationRoute.withdraw) {
                ProfileMenuButtonRow(title: "회원 탈퇴", isDestructive: true)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(viewModel.myProfile == nil)
    }

    private func profileInfoRow(systemImage: String, title: String, value: String?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .resizable(resizingMode: .stretch)
                .aspectRatio(contentMode: .fit)
                .frame(width: 22)
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .frame(width: 60, alignment: .leading)
            Text(value ?? "미설정")
                .font(.system(size: 15))
                .foregroundStyle(value != nil ? .black : .gray)

            Spacer()
        }
    }
}

// 추후 제거 예정
fileprivate struct DummyView: View {
    
    let navigationTitle: String
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 20))
            .navigationTitle(navigationTitle)
    }
}

#Preview {
    var viewModel = MockProfileViewModel()
    ProfileView(viewModel: viewModel)
}
