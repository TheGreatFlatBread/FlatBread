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

        print("   [FCMManager] 토큰 전송 시작 (시도 \(retryCount + 1)/3)")
        print("   userId: \(targetUserId)")
        print("   fcmToken: \(fcmToken.prefix(20))...")
        print("   deviceID: \(deviceID)")

        let functions = Functions.functions(region: "asia-northeast3")
        let callable = functions.httpsCallable("updateFCMToken")

        let data: [String: Any] = [
            "userId": targetUserId,
            "fcmToken": fcmToken,
            "deviceID": deviceID
        ]

        print("[FCMManager] Firebase Functions 호출 중... (updateFCMToken)")

        // Timeout 타이머 (15초)
        var hasCompleted = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            if !hasCompleted {
                print("   [FCMManager] 타임아웃 (15초) - 응답 없음")
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
                print("[FCMManager] 응답이 타임아웃 후에 도착함 - 무시")
                return
            }
            hasCompleted = true

            print("[FCMManager] 응답 수신!")

            if let error = error as NSError? {
                print("[FCMManager] 토큰 업데이트 실패 (시도 \(retryCount + 1)/3)")
                print("Domain: \(error.domain)")
                print("Code: \(error.code)")
                print("Description: \(error.localizedDescription)")

                if let details = error.userInfo["details"] {
                    print("   Details: \(details)")
                }

                if retryCount < 2 {
                    let delay = Double(retryCount + 1) * 2.0
                    print("[FCMManager] \(Int(delay))초 후 재시도...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.sendTokenToBackend(fcmToken: fcmToken, userId: targetUserId, retryCount: retryCount + 1)
                    }
                } else {
                    print("[FCMManager] 최대 재시도 횟수 초과 - Pending 토큰으로 저장")
                    UserSession.shared.savePendingFCMToken(fcmToken)
                }
            } else {
                print("   [FCMManager] 토큰 업데이트 성공!")
                print("   userId: \(targetUserId)")
                if let resultData = result?.data {
                    print("   Response: \(resultData)")
                }
                UserSession.shared.clearPendingFCMToken()
            }
        }
    }

    /// 이전 FCM 토큰 제거 (토큰 갱신 시)
    func removeOldToken(userId: String, oldToken: String) {
        print("[FCMManager] 이전 토큰 제거 요청")
        print("userId: \(userId)")
        print("oldToken: \(oldToken.prefix(20))...")

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
        print("[FCMManager] 로그아웃 - 토큰 제거 요청")
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
                print("[FCMManager] 토큰 제거 실패: \(error.localizedDescription)")
            } else {
                print("[FCMManager] 토큰 제거 성공")
            }
        }
    }
}
