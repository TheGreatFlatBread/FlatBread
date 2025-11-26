//
//  ShortVideoCommentViewModel.swift
//  FlatBread
//
//  Created by 김민성 on 11/26/25.
//

import Foundation
import Combine

@MainActor
final class ShortVideoCommentViewModel: ObservableObject {
    
    // 댓글, 로딩 관련
    @Published var comments: [CommentReplyResponseDTO] = []
    var isLoading: Bool = false
    
    // 텍스트 입력 관련
    @Published var inputText: String = ""
    @Published var replyingTo: CommentReplyResponseDTO? = nil
    
    // alert 표시 관련
    @Published var showingAlert: Bool = false
    var alertMessage: String = ""
    
    @Published var myProfile: ShortVideoProfile? = nil
    
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    private let videoID: String
    
    init(videoID: String) {
        self.videoID = videoID
    }
    
    /// 댓글 목록 조회
    func fetchComments() async {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: 실제 API 엔드포인트 라우터로 교체 필요
         let router = CommentRouter.getCommentList(postID: videoID)
        
        do {
            // [Mock] 네트워크 요청 코드 예시 (사용자가 작성할 부분)
             let response = try await networkService.request(router, responseType: CommentListResponseDTO.self)
             self.comments = response.data
        } catch {
            print("❌ 댓글 조회 실패: \(error)")
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
    
    // 댓글 또는 대댓글 전송
    func sendComment() async {
        guard !inputText.isEmpty else { return }
        
        let contentToSend = inputText
        let targetCommentID = replyingTo?.commentID
        
        // 입력창 텍스트 UI는 즉시 초기화하도록 구현했습니다ㅏ. (Optimistic UI)
        inputText = ""
        replyingTo = nil
        
        do {
            if let parentID = targetCommentID {
                // 대댓글 작성
                let router = CommentRouter.writeSubComment(postID: videoID, commentID: parentID, content: contentToSend)
                let _ = try await networkService.request(router, responseType: CommentResponseDTO.self)
                await fetchComments()
            } else {
                // 일반 댓글 작성
                let router = CommentRouter.writeComment(postID: videoID, content: contentToSend)
                let _ = try await networkService.request(router, responseType: CommentResponseDTO.self)
                await fetchComments()
            }
        } catch {
            print("❌ 댓글 작성 실패: \(error)")
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
    
    // 답글 달기 모드 설정
    func setReplyTarget(_ comment: CommentReplyResponseDTO) {
        self.replyingTo = comment
    }
    
    // 답글 달기 취소
    func cancelReply() {
        self.replyingTo = nil
    }
    
    func updateMyProfile() async {
        let router = UserRouter.getMeProfile
        do {
            let myUpdatedProfile = try await networkService.request(router, responseType: UserProfileResponseDTO.self).asShortVideoProfile
            self.myProfile = myUpdatedProfile
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
}
