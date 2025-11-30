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
    @EnvironmentObject var router: TabRouter<ProfileDestination>

    init(viewModel: ProfileViewModel = ProfileViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            ScrollView {
                VStack(spacing: 24) {
                    if let profile = viewModel.myProfile {
                        profileInfoSection(profile: profile)
                    } else if viewModel.isLoadingProfile {
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(height: 60)
                    } else {
                        profileInfoSection(profile: nil)
                    }
                    menuSection
                }
                .padding()
            }
            .navigationTitle("내 프로필")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .navigationDestination(for: ProfileDestination.self) { destination in
                switch destination {
                case .editProfile:
                    if let profile = viewModel.myProfile {
                        EditProfileView(userProfile: profile) {
                            Task {
                                await viewModel.requestMyProfile()
                                viewModel.alertTitle = "성공"
                                viewModel.alertMessage = "프로필이 업데이트되었습니다."
                                viewModel.showingAlert = true
                            }
                        }
                    } else {
                        Text("프로필 정보를 불러오는 중입니다…")
                    }
                case .myMoim:
                    DummyView(navigationTitle: "내가 만든 모임", text: "내 모임")
                case .makeNewMoim:
                    DummyView(navigationTitle: "새 모임 만들기", text: "새 모임")
                case .chatList:
                    MoimChatListView(currentUserID: viewModel.myProfile?.userID ?? "")
                case .chatRoom(let room):
                    ChatRoomView(room: room, currentUserID: viewModel.myProfile?.userID ?? UserSession.shared.currentUserId ?? "")
                case .withdraw:
                    // 탈퇴 기능은 추후 alert로 대체
//                    DummyView(navigationTitle: "탈퇴하기", text: "탈퇴")
                    VideoUploadView()
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
    
    private func profileInfoSection(profile: UserProfileResponseDTO?) -> some View {
        if let profile = profile {
            return AnyView(profileInfoSection(profile: profile))
        } else {
            return AnyView(
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .foregroundColor(.gray)
                        Text("닉네임 없음")
                            .font(.system(size: 20, weight: .bold))
                        Spacer()
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 12) {
                        profileInfoRow(systemImage: "envelope.fill", title: "이메일", value: nil)
                        profileInfoRow(systemImage: "calendar", title: "생년월일", value: nil)
                        profileInfoRow(systemImage: "person.fill", title: "성별", value: nil)
                        profileInfoRow(systemImage: "phone.fill", title: "전화번호", value: nil)
                    }
                    Button {
                        router.navigate(to: .editProfile)
                    } label: {
                        HStack { Spacer(); Text("수정").foregroundStyle(.white).frame(height: 40); Spacer() }
                            .background(.orange)
                            .cornerRadius(14)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(true)
                }
                .padding(20)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(32)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
    }

    private func profileInfoSection(profile: UserProfileResponseDTO) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                if let urlString = profile.profileImage, !urlString.isEmpty {
                    RemoteImage(url: urlString, displayMode: .thumbnail(CGSize(width: 60, height: 60))) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .foregroundColor(.gray)
                    } content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .foregroundColor(.gray)
                }

                Text(profile.nick ?? "닉네임 없음")
                    .font(.system(size: 20, weight: .bold))

                Spacer()
            }

            Divider()
            VStack(alignment: .leading, spacing: 12) {
                profileInfoRow(
                    systemImage: "envelope.fill",
                    title: "이메일",
                    value: profile.email
                )
                profileInfoRow(
                    systemImage: "calendar",
                    title: "생년월일",
                    value: profile.birthDay
                )
                profileInfoRow(
                    systemImage: "person.fill",
                    title: "성별",
                    value: genderDisplay(from: profile.gender)
                )
                profileInfoRow(
                    systemImage: "phone.fill",
                    title: "전화번호",
                    value: profile.phoneNum
                )
            }

            Button {
                router.navigate(to: .editProfile)
            } label: {
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

    private func genderDisplay(from gender: String?) -> String? {
        guard let gender else { return nil }
        switch gender {
        case "male": return "남성"
        case "female": return "여성"
        default: return "기타"
        }
    }

    // MARK: - 메뉴 버튼 섹션
    private var menuSection: some View {
        VStack(spacing: 12) {
            VStack(spacing: 0) {
                Button {
                    router.navigate(to: .myMoim)
                } label: {
                    ProfileMenuButtonRow(title: "내가 만든 모임 확인하기")
                }

                Button {
                    router.navigate(to: .makeNewMoim)
                } label: {
                    ProfileMenuButtonRow(title: "새 모임 만들기")
                }

                Button {
                    router.navigate(to: .chatList)
                } label: {
                    ProfileMenuButtonRow(title: "채팅 목록")
                }
            }
            .padding(10)
            .background(.white)
            .cornerRadius(32)

            Button {
                router.navigate(to: .withdraw)
            } label: {
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
