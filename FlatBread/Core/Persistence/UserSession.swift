//
//  UserSession.swift
//  FlatBread
//
//  사용자 세션 관리 싱글톤
//  - userId 저장/조회
//  - 로그인/로그아웃 상태 관리
//  - FCM 토큰 pending 처리
//

import Foundation
import UIKit
import FirebaseMessaging

final class UserSession {
    static let shared = UserSession()

    private init() {}
    
    var currentUserId: String? {
        get {
            UserDefaults.standard.string(forKey: "currentUserId")
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: "currentUserId")
            } else {
                UserDefaults.standard.removeObject(forKey: "currentUserId")
            }
        }
    }

    var isLoggedIn: Bool {
        currentUserId != nil
    }

    func login(userId: String, sendPendingToken: Bool = true) {
        self.currentUserId = userId
        if sendPendingToken {
            // FCMManager를 통해 Pending 토큰 전송
            FCMManager.shared.sendPendingToken()
        }
    }

    /// 로그아웃 처리
    func logout() {
        let previousUserId = currentUserId
        self.currentUserId = nil
        // 로그아웃 시 백엔드에서 FCM 토큰 제거
        removeFCMTokenFromBackend(userId: previousUserId)
    }

    /// 백엔드에서 FCM 토큰 제거 (로그아웃 시)
    private func removeFCMTokenFromBackend(userId: String?) {
        guard let userId = userId,
              let fcmToken = currentFCMToken else {
            return
        }
        // FCMManager를 통해 토큰 제거
        FCMManager.shared.removeTokenFromBackend(userId: userId, fcmToken: fcmToken)

        // deleteAndRegenerateFCMToken()
    }

    /// FCM 토큰 삭제 후 재생성 (로그아웃 시 완전히 새 토큰 받기)
    /// - 보안이 중요한 경우 사용
    /// - 로그아웃 시 이전 토큰으로 절대 푸시 못 받게 함
    private func deleteAndRegenerateFCMToken() {
        Messaging.messaging().deleteToken { error in
            if let error {
            } else {
                // 새 토큰 요청 (자동으로 생성되고 didReceiveRegistrationToken에서 받음)
                Messaging.messaging().token { token, error in
                    if let token {
                        // 새 토큰은 Pending으로 저장됨 (다음 로그인 시 전송)
                        self.savePendingFCMToken(token)
                    }
                }
            }
        }
    }

    // MARK: - Pending FCM Token

    /// Pending FCM 토큰 저장
    /// - Parameter token: FCM 토큰
    func savePendingFCMToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "PendingFCMToken")
    }

    /// Pending FCM 토큰 조회
    /// - Returns: 저장된 Pending FCM 토큰 (없으면 nil)
    func getPendingFCMToken() -> String? {
        UserDefaults.standard.string(forKey: "PendingFCMToken")
    }

    /// Pending FCM 토큰 삭제
    func clearPendingFCMToken() {
        UserDefaults.standard.removeObject(forKey: "PendingFCMToken")
    }

    // MARK: - FCM Token Management
    /// 현재 FCM 토큰 조회
    var currentFCMToken: String? {
        return UserDefaults.standard.string(forKey: "fcmToken")
    }

    /// FCM 토큰 삭제 (로그아웃 시 선택적으로 사용)
    private func clearFCMToken() {
        UserDefaults.standard.removeObject(forKey: "fcmToken")
    }
}
