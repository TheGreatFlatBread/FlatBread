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

    // MARK: - APNs Token Registration
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
                    removeOldFCMToken(userId: userId, oldToken: oldToken)
                }
            } else {
                print("[FCM] 최초 토큰 수신")
            }

            // 서버에 새 FCM 토큰 전송 (변경되었을 때만)
            sendTokenToBackend(fcmToken: fcmToken)
        } else {
            print("[FCM] 토큰 변경 없음 - 서버 전송 스킵")
        }
    }

    /// 이전 FCM 토큰 제거 (토큰 갱신 시)
    private func removeOldFCMToken(userId: String, oldToken: String) {
        print("[FCM] 이전 토큰 제거 요청")
        print("userId: \(userId)")
        print("oldToken: \(oldToken.prefix(20))...")

        let functions = Functions.functions(region: "asia-northeast3")
        let callable = functions.httpsCallable("removeOldFCMToken")

        callable.call([
            "userId": userId,
            "oldToken": oldToken
        ]) { result, error in
            if let error = error {
                print("[FCM] 이전 토큰 제거 실패: \(error.localizedDescription)")
            } else {
                print("q[FCM] 이전 토큰 제거 성공")
            }
        }
    }


    // 백엔드로 토큰 전송 (Retry 로직 포함)
    func sendTokenToBackend(fcmToken: String, retryCount: Int = 0) {
        guard let userId = UserSession.shared.currentUserId else {
            print("[FCM] 로그인되지 않음 - Pending 토큰으로 저장")
            UserSession.shared.savePendingFCMToken(fcmToken)
            return
        }

        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"

        print("   [FCM] 토큰 전송 시작 (시도 \(retryCount + 1)/3)")
        print("   userId: \(userId)")
        print("   fcmToken: \(fcmToken)...")
        print("   deviceID: \(deviceID)")

        // Firebase Functions 리전 설정 (서울 = asia-northeast3)
        let functions = Functions.functions(region: "asia-northeast3")
        let callable = functions.httpsCallable("updateFCMToken")

        let data: [String: Any] = [
            "userId": userId,
            "fcmToken": fcmToken,
            "deviceID": deviceID
        ]

        print("[FCM] Firebase Functions 호출 중... (updateFCMToken)")

        // Timeout 타이머 (15초)
        var hasCompleted = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            if !hasCompleted {
                print("   [FCM] 타임아웃 (30초) - 응답 없음")
                hasCompleted = true

                if retryCount < 2 {
                    let delay = Double(retryCount + 1) * 2.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.sendTokenToBackend(fcmToken: fcmToken, retryCount: retryCount + 1)
                    }
                } else {
                    UserSession.shared.savePendingFCMToken(fcmToken)
                }
            }
        }

        callable.call(data) { result, error in
            guard !hasCompleted else {
                print("[FCM] 응답이 타임아웃 후에 도착함 - 무시")
                return
            }
            hasCompleted = true

            print("[FCM] 응답 수신!")

            if let error = error as NSError? {
                print("[FCM] 토큰 업데이트 실패 (시도 \(retryCount + 1)/3)")
                print("Domain: \(error.domain)")
                print("Code: \(error.code)")
                print("Description: \(error.localizedDescription)")

                if let details = error.userInfo["details"] {
                    print("   Details: \(details)")
                }

                if retryCount < 2 {
                    let delay = Double(retryCount + 1) * 2.0
                    print("[FCM] \(Int(delay))초 후 재시도...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.sendTokenToBackend(fcmToken: fcmToken, retryCount: retryCount + 1)
                    }
                } else {
                    print("[FCM] 최대 재시도 횟수 초과 - Pending 토큰으로 저장")
                    UserSession.shared.savePendingFCMToken(fcmToken)
                }
            } else {
                print("   [FCM] 토큰 업데이트 성공!")
                print("   userId: \(userId)")
                if let resultData = result?.data {
                    print("   Response: \(resultData)")
                }
                UserSession.shared.clearPendingFCMToken()
            }
        }
    }

    // MARK: - Remove FCM Token (Logout)

    /// 로그아웃 시 백엔드에서 FCM 토큰 제거
    func removeFCMTokenFromBackend(userId: String, fcmToken: String) {
        print(" [FCM] 로그아웃 - 토큰 제거 요청")
        print("   userId: \(userId)")
        print("   fcmToken: \(fcmToken.prefix(20))...")

        let functions = Functions.functions(region: "asia-northeast3")
        let callable = functions.httpsCallable("removeFCMToken")

        let data: [String: Any] = [
            "userId": userId,
            "fcmToken": fcmToken
        ]

        callable.call(data) { result, error in
            if let error = error {
                print(" [FCM] 토큰 제거 실패: \(error.localizedDescription)")
            } else {
                print(" [FCM] 토큰 제거 성공")
            }
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
        
        // completionHandler([.banner, .sound, .badge])
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
        // TODO: 알림 타입에 따라 화면 이동 처리
        // 예시:
        // if let chatRoomId = userInfo["chatRoomId"] as? String {
        //     NotificationCenter.default.post(
        //         name: NSNotification.Name("NavigateToChatRoom"),
        //         object: nil,
        //         userInfo: ["chatRoomId": chatRoomId]
        //     )
        // }
    }
}
