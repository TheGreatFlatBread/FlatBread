//
//  ShortVideoCommentRow.swift
//  FlatBread
//
//  Created by 김민성 on 11/26/25.
//

import SwiftUI

struct ShortVideoCommentRow: View {
    let comment: CommentReplyResponseDTO
    let onReplyTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 부모 댓글
            commentContent(
                creator: comment.creator,
                content: comment.content,
                date: comment.createdAt,
                isReply: false
            )
            
            // 대댓글 리스트 (들여쓰기)
            if !comment.replies.isEmpty {
                // 대댓글은 시간 오름차순으로 표시 (reversed() 적용)
                ForEach(comment.replies.reversed()) { reply in
                    HStack {
                        Spacer().frame(width: 40) // 들여쓰기
                        commentContent(
                            creator: reply.creator,
                            content: reply.content,
                            date: reply.createdAt,
                            isReply: true
                        )
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func commentContent(creator: CreatorResponseDTO?, content: String?, date: String?, isReply: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RemoteImage(
                url: creator?.profileImage ?? "",
                displayMode: .thumbnail(.init(width: isReply ? 26 : 30, height: isReply ? 26 : 30)),
                content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            )
            .frame(width: isReply ? 26 : 30, height: isReply ? 26 : 30)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(creator?.nick ?? "알 수 없음")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text(date?.toDate()?.asShortVideoCommentFormat ?? "")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Text(content ?? "")
                    .font(.system(size: 14))
                    .lineLimit(nil)
                
                // 부모 댓글인 경우에만 '답글 달기' 버튼 표시
                if !isReply {
                    Button {
                        onReplyTap()
                    } label: {
                        Text("답글 달기")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 2)
                }
            }
            Spacer()
        }
    }
}

//#Preview {
//    ShortVideoCommentRow()
//}
