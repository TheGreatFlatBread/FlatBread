//
//  AppDelegate.swift
//  FlatBread
//
//  Created by andev on 11/25/25.
//

import UIKit
import iamport_ios
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import Alamofire
import FirebaseFunctions

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().isAutoInitEnabled = true
        Messaging.messaging().delegate = self
        setupPushNotifications(application: application)
        return true
    }

    // MARK: - Push Notification Setup
    private func setupPushNotifications(application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { [weak application] granted, error in
            if let error {
                print("requestAuthorization Error: \(error)")
                return
            }
            if granted {
                DispatchQueue.main.async {
                    guard let application else { return }
                    application.registerForRemoteNotifications()
                }
            }
        }
    }

    // APNs 토큰 등록 성공
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs Token 등록 성공: \(tokenString)")
    }

    // APNs 토큰 등록 실패
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs 등록 실패: \(error.localizedDescription)")
    }

    // 외부 앱에서 인증 또는 결제 후 다시 서비스 앱으로 돌아올 때 전달되는 URL을 처리하는 메서드
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        Iamport.shared.receivedURL(url)
        return true
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    // FCM 토큰 갱신 시 호출
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            print("[FCM] 토큰이 nil입니다.")
            return
        }

        print("[FCM] 새 토큰 수신: \(fcmToken.prefix(20))...")
        // 이전 토큰 확인
        let oldToken = UserDefaults.standard.string(forKey: "fcmToken")

        // 토큰이 변경되었는지 확인
        let isTokenChanged = (oldToken != fcmToken)

        // 로컬에 저장
        UserDefaults.standard.set(fcmToken, forKey: "fcmToken")

        // 토큰이 변경되었을 때만 서버에 전송
        if isTokenChanged {
            if let oldToken = oldToken {
                print("[FCM] 토큰 갱신 감지!")
                print("Old: \(oldToken.prefix(20))...")
                print("New: \(fcmToken.prefix(20))...")

                // 백엔드에서 old 토큰 제거 요청
                if let userId = UserSession.shared.currentUserId {
                    FCMManager.shared.removeOldToken(userId: userId, oldToken: oldToken)
                }
            } else {
                print("[FCM] 최초 토큰 수신")
            }

            // 서버에 새 FCM 토큰 전송 (변경되었을 때만)
            FCMManager.shared.sendTokenToBackend(fcmToken: fcmToken)
        } else {
            print("[FCM] 토큰 변경 없음 - 서버 전송 스킵")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    // 앱이 foreground에 있을 때 알림 수신
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        if let aps = userInfo["aps"] as? [String: Any] {
            if let alert = aps["alert"] as? String {
                print("알림 내용: \(alert)")
            }
        }
        completionHandler([.banner, .sound, .badge])
    }

    // 알림 탭했을 때 호출
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("알림 탭: \(userInfo)")
        // 알림 데이터 처리
        handleNotificationTap(userInfo: userInfo)

        completionHandler()
    }

    // MARK: - Notification Handler
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        print("========================================")
        print("[FCM] 알림 데이터 전체:")
        print(userInfo)
        print("========================================")

        var deepLinkPath: String?

        if let type = userInfo["type"] as? String {
            print("[FCM] type: \(type)")
            switch type {
            case "chat":
                print("[FCM] roomId 확인 중...")
                print("[FCM] userInfo[\"roomId\"]: \(userInfo["roomId"] ?? "nil")")

                if let roomId = userInfo["roomId"] as? String {
                    print("[FCM] roomId 발견: \(roomId)")
                    deepLinkPath = "FlatBread://chat/\(roomId)"
                } else {
                    print("[FCM] roomId가 없음 - 채팅 딥링크 실패")
                }

            default:
                print("[FCM] 지원하지 않는 type: \(type)")
                break
            }
        }

        if deepLinkPath == nil, let deepLink = userInfo["deepLink"] as? String {
            deepLinkPath = deepLink
        }

        if let path = deepLinkPath, let url = URL(string: path) {
            print("[FCM] ========================================")
            print("[FCM] 딥링크 처리: \(path)")

            // 앱 상태 확인
            let appState = UIApplication.shared.applicationState
            let stateString = appState == .active ? "Active (Foreground)" : appState == .background ? "Background" : "Inactive"
            print("[FCM] 현재 앱 상태: \(stateString)")

            // 모든 경우에 NotificationCenter 사용
            if appState != .active {
                // Background/Inactive: 딜레이 후 처리
                print("[FCM] Background/Inactive - 1초 후 처리")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    print("[FCM] DeepLink 전송 (딜레이 후)")
                    NotificationCenter.default.post(
                        name: .handleDeepLink,
                        object: url
                    )
                }
            } else {
                // Foreground: 즉시 처리
                print("[FCM] DeepLink 전송 (즉시)")
                NotificationCenter.default.post(
                    name: .handleDeepLink,
                    object: url
                )
            }
            print("[FCM] ========================================")
        } else {
            print("[FCM] ❌ 딥링크 파싱 실패 - userInfo: \(userInfo)")
        }
    }
}
