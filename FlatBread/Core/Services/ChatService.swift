//
//  ChatService.swift
//  FlatBread
//
//  Created by hwan on 11/28/25.
//

import Foundation
import FirebaseFunctions

final class ChatService {
    private let functions: Functions

    init() {
        // Firebase Functions 리전 설정 (서울 = asia-northeast3)
        self.functions = Functions.functions(region: "asia-northeast3")
    }

    // MARK: - Push Notification

    /// 푸시 알림 전송 (Firebase Cloud Function 호출)
    /// - Parameters:
    ///   - receiverId: 수신자 ID
    ///   - roomId: 채팅방 ID
    ///   - message: 메시지 내용
    ///   - messageType: 메시지 타입 ("text", "image", "video" 등)
    ///   - senderNickname: 발신자 닉네임 (선택)
    ///   - completion: 완료 핸들러
    func sendPushNotification(
        receiverId: String,
        roomId: String,
        message: String,
        messageType: String = "text",
        senderNickname: String? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // UserSession에서 senderId 가져오기
        guard let senderId = UserSession.shared.currentUserId else {
            let error = NSError(
                domain: "ChatService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "로그인되지 않음"]
            )
            completion(.failure(error))
            return
        }

        let callable = functions.httpsCallable("sendChatPush")

        var data: [String: Any] = [
            "senderId": senderId,
            "receiverId": receiverId,
            "roomId": roomId,
            "message": message,
            "messageType": messageType
        ]

        if let senderNickname = senderNickname {
            data["nickname"] = senderNickname
        }
        
        callable.call(data) { result, error in
            if let error {
                completion(.failure(error))
                return
            }

            // 성공 응답 처리
            if let data = result?.data as? [String: Any],
               let success = data["success"] as? Bool {
                if success {
                    completion(.success(()))
                } else {
                    let reason = data["reason"] as? String ?? "unknown"
                    // 실패여도 메시지는 전송되었으므로 success로 처리
                    completion(.success(()))
                }
            } else {
                // 응답 형식이 다르거나 없는 경우도 success
                completion(.success(()))
            }
        }
    }

    /// 메시지 전송 + 푸시 알림 통합 메서드
    /// - Parameters:
    ///   - receiverId: 수신자 ID
    ///   - roomId: 채팅방 ID
    ///   - message: 메시지 내용
    ///   - messageType: 메시지 타입
    ///   - saveMessageLocally: 로컬 저장 콜백 (Realm/Core Data)
    ///   - completion: 완료 핸들러
    func sendMessage(
        to receiverId: String,
        roomId: String,
        message: String,
        messageType: String = "text",
        saveMessageLocally: @escaping () -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // 1. 로컬에 메시지 저장
        saveMessageLocally()

        // 2. 푸시 알림 전송
        sendPushNotification(
            receiverId: receiverId,
            roomId: roomId,
            message: message,
            messageType: messageType,
            completion: completion
        )
    }
}

// MARK: - Async/Await Support

extension ChatService {
    /// 푸시 알림 전송 (Async/Await)
    func sendPushNotification(
        receiverId: String,
        roomId: String,
        message: String,
        messageType: String = "text",
        senderNickname: String? = nil
    ) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            sendPushNotification(
                receiverId: receiverId,
                roomId: roomId,
                message: message,
                messageType: messageType,
                senderNickname: senderNickname
            ) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// 메시지 전송 + 푸시 알림 (Async/Await)
    func sendMessage(
        to receiverId: String,
        roomId: String,
        message: String,
        messageType: String = "text",
        saveMessageLocally: @escaping () -> Void
    ) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            sendMessage(
                to: receiverId,
                roomId: roomId,
                message: message,
                messageType: messageType,
                saveMessageLocally: saveMessageLocally
            ) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
