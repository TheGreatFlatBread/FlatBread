import SwiftUI
import Combine

// MARK: - Navigation Destinations per Tab

enum HomeDestination: Hashable {
    case createMoim
    case moimDetail(String)
    case categoryDetail
    case postList(String) // moimId
}

enum ProfileDestination: Hashable {
    case editProfile
    case myMoim
    case makeNewMoim
    case chatList
    case chatRoom(ChatRoomModel)
    case withdraw
}

enum MyMoimDestination: Hashable {
    case moimDetail(String)
    case postList(String)
}

enum ShortVideoDestination: Hashable {
    case videoDetail(String)
    case comments(String)
}

enum MapDestination: Hashable {
    case moimDetail(String)
    case focusOnMoim(String)
}

// MARK: - Unified AppDestination (for cross-tab navigation)
enum AppDestination: Hashable {
    case home(HomeDestination)
    case profile(ProfileDestination)
    case myMoim(MyMoimDestination)
    case shortVideo(ShortVideoDestination)
    case map(MapDestination)
}

// MARK: - Tab Router (Generic)
final class TabRouter<Destination: Hashable>: ObservableObject {
    @Published var path = NavigationPath()

    func navigate(to destination: Destination) {
        path.append(destination)
    }

    func navigateToRoot() {
        path.removeLast(path.count)
    }

    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
}

// MARK: - Tab Type
enum TabType: Int, Hashable {
    case home = 0
    case shortVideo = 1
    case map = 2
    case myMoim = 3
    case profile = 4
}

// MARK: - Main Navigation Coordinator
class NavigationCoordinator: ObservableObject {
    // 현재 선택된 탭
    @Published var selectedTab: TabType = .home

    // 각 탭별 Router (타입 안전)
    @Published var homeRouter = TabRouter<HomeDestination>()
    @Published var shortVideoRouter = TabRouter<ShortVideoDestination>()
    @Published var mapRouter = TabRouter<MapDestination>()
    @Published var myMoimRouter = TabRouter<MyMoimDestination>()
    @Published var profileRouter = TabRouter<ProfileDestination>()

    func resetAll() {
        homeRouter.navigateToRoot()
        shortVideoRouter.navigateToRoot()
        mapRouter.navigateToRoot()
        myMoimRouter.navigateToRoot()
        profileRouter.navigateToRoot()
    }

    func switchTab(to tab: TabType, andNavigate destination: AppDestination? = nil) {
        selectedTab = tab

        guard let destination = destination else { return }

        // AppDestination을 각 탭의 destination으로 변환 후 push
        switch destination {
        case .home(let dest):
            homeRouter.navigate(to: dest)
        case .profile(let dest):
            profileRouter.navigate(to: dest)
        case .myMoim(let dest):
            myMoimRouter.navigate(to: dest)
        case .shortVideo(let dest):
            shortVideoRouter.navigate(to: dest)
        case .map(let dest):
            mapRouter.navigate(to: dest)
        }
    }
}
