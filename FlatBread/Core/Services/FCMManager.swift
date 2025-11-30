//
//  FCMManager.swift
//  FlatBread
//
//  Created by hwan on 11/29/25.
//

import Foundation
import UIKit
import FirebaseFunctions

final class FCMManager {
    static let shared = FCMManager()

    private init() {}

    func sendPendingToken() {
        guard let userId = UserSession.shared.currentUserId,
              let pendingToken = UserSession.shared.getPendingFCMToken() else {
            return
        }
        sendTokenToBackend(fcmToken: pendingToken, userId: userId)
    }

    func sendTokenToBackend(fcmToken: String, userId: String? = nil, retryCount: Int = 0) {
        let targetUserId = userId ?? UserSession.shared.currentUserId

        guard let targetUserId else {
            UserSession.shared.savePendingFCMToken(fcmToken)
            return
        }

        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"

        let functions = Functions.functions(region: "asia-northeast3")
        let callable = functions.httpsCallable("updateFCMToken")

        let data: [String: Any] = [
            "userId": targetUserId,
            "fcmToken": fcmToken,
            "deviceID": deviceID
        ]
        // Timeout 타이머 (15초)
        var hasCompleted = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            if !hasCompleted {
                hasCompleted = true

                if retryCount < 2 {
                    let delay = Double(retryCount + 1) * 2.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.sendTokenToBackend(fcmToken: fcmToken, userId: targetUserId, retryCount: retryCount + 1)
                    }
                } else {
                    UserSession.shared.savePendingFCMToken(fcmToken)
                }
            }
        }

        callable.call(data) { result, error in
            guard !hasCompleted else {
                return
            }
            hasCompleted = true
            if let error = error as NSError? {
                if retryCount < 2 {
                    let delay = Double(retryCount + 1) * 2.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.sendTokenToBackend(fcmToken: fcmToken, userId: targetUserId, retryCount: retryCount + 1)
                    }
                } else {
                    UserSession.shared.savePendingFCMToken(fcmToken)
                }
            } else {
                UserSession.shared.clearPendingFCMToken()
            }
        }
    }

    /// 이전 FCM 토큰 제거 (토큰 갱신 시)
    func removeOldToken(userId: String, oldToken: String) {
        let functions = Functions.functions(region: "asia-northeast3")
        let callable = functions.httpsCallable("removeOldFCMToken")

        callable.call([
            "userId": userId,
            "oldToken": oldToken
        ]) { result, error in
            if let error = error {
                print("[FCMManager] 이전 토큰 제거 실패: \(error.localizedDescription)")
            } else {
                print("[FCMManager] 이전 토큰 제거 성공")
            }
        }
    }

    /// 로그아웃 시 백엔드에서 FCM 토큰 제거
    func removeTokenFromBackend(userId: String, fcmToken: String) {
        let functions = Functions.functions(region: "asia-northeast3")
        let callable = functions.httpsCallable("removeFCMToken")

        let data: [String: Any] = [
            "userId": userId,
            "fcmToken": fcmToken
        ]

        callable.call(data) { result, error in
            if let error = error {
                print("[FCMManager] 토큰 제거 실패: \(error.localizedDescription)")
            } else {
                print("[FCMManager] 토큰 제거 성공")
            }
        }
    }
}
