//
//  ErrorContext.swift
//  FlatBread
//
//  Created by hwan on 11/19/25.
//

import UIKit

/// 에러가 발생한 컨텍스트 (어떤 작업 중에 발생했는지)
enum ErrorContext {
    case postUpload         // 게시물 업로드
    case imageUpload        // 이미지 업로드
    case postFetch          // 게시물 조회
    case login              // 로그인
    case profileUpdate      // 프로필 업데이트
    case chatSend           // 채팅 전송
    case moimCreate         // 모임 생성
    case unknown            // 알 수 없음
}

/// 에러 액션 (사용자가 취할 수 있는 행동)
struct ErrorAction {
    let title: String
    let style: Style
    let handler: () -> Void

    enum Style {
        case `default`
        case destructive
        case cancel
    }

    static func retry(_ handler: @escaping () -> Void) -> ErrorAction {
        ErrorAction(title: "다시 시도", style: .default, handler: handler)
    }

    static func confirm(_ handler: @escaping () -> Void = {}) -> ErrorAction {
        ErrorAction(title: "확인", style: .cancel, handler: handler)
    }

    static func openSettings(_ handler: @escaping () -> Void) -> ErrorAction {
        ErrorAction(title: "설정 열기", style: .default, handler: handler)
    }
}

extension NetworkError {
    /// 컨텍스트 기반 사용자 메시지
    func userMessage(context: ErrorContext) -> String {
        switch (self, context) {
        // 인터넷 연결 없음
        case (.noInternetConnection, .postUpload):
            return "게시물을 업로드할 수 없습니다.\n인터넷 연결을 확인해주세요."
        case (.noInternetConnection, .imageUpload):
            return "이미지를 업로드할 수 없습니다.\n인터넷 연결을 확인해주세요."
        case (.noInternetConnection, .chatSend):
            return "메시지를 전송할 수 없습니다.\n인터넷 연결을 확인해주세요."
        case (.noInternetConnection, _):
            return "인터넷 연결을 확인해주세요."

        // 타임아웃
        case (.timeout, .postUpload):
            return "게시물 업로드 시간이 초과되었습니다.\n다시 시도해주세요."
        case (.timeout, .imageUpload):
            return "이미지 업로드 시간이 초과되었습니다.\n다시 시도해주세요."
        case (.timeout, _):
            return "요청 시간이 초과되었습니다.\n다시 시도해주세요."

        // API 에러
        case (.apiError(.invalidAccessToken), _),
             (.apiError(.expiredAccessToken), _):
            return "로그인이 필요합니다.\n다시 로그인해주세요."
        case (.apiError(.execcedApiLimit), _):
            return "너무 많은 요청을 보냈습니다.\n잠시 후 다시 시도해주세요."
        case (.apiError(.internalServerError), _):
            return "서버에 일시적인 문제가 발생했습니다.\n잠시 후 다시 시도해주세요."

        // 업로드 실패
        case (.uploadFailed, .postUpload):
            return "게시물 업로드에 실패했습니다."
        case (.uploadFailed, .imageUpload):
            return "이미지 업로드에 실패했습니다."

        // 기본 메시지
        default:
            return errorDescription ?? "알 수 없는 오류가 발생했습니다."
        }
    }

    /// 재시도 가능 여부
    var isRetryable: Bool {
        switch self {
        case .networkFailure, .timeout, .noInternetConnection, .uploadFailed:
            return true
        case .apiError(let fbError):
            switch fbError {
            case .execcedApiLimit, .internalServerError:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }

    /// 사용자가 취할 수 있는 액션들
    func actions(context: ErrorContext, retry: @escaping () -> Void) -> [ErrorAction] {
        switch self {
        // 재시도 가능한 에러
        case _ where isRetryable:
            return [
                .retry(retry),
                .confirm()
            ]

        // 인터넷 연결 없음 -> 설정 열기
        case .noInternetConnection:
            return [
                .openSettings {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                },
                .confirm()
            ]

        // 인증 에러 -> 로그인 화면으로
        case .apiError(.invalidAccessToken),
             .apiError(.expiredAccessToken):
            return [
                ErrorAction(title: "로그인", style: .default) {
                    // TODO: 로그인 화면으로 이동
                },
                .confirm()
            ]

        // 기본: 확인만
        default:
            return [.confirm()]
        }
    }
}
