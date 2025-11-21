//
//  ShortFormFeedView.swift
//  FlatBread
//
//  Created by 김민성 on 11/20/25.
//

import SwiftUI

// 데이터 모델
struct ShortFormVideo: Identifiable, Hashable {
    let id = UUID()
    let filePath: String
    let description: String
}

struct ShortFormFeedView: View {
    // 테스트용 서버 동영상 데이터
    let videos: [ShortFormVideo] = [
        // 버스
        ShortFormVideo(
            filePath:  "/data/posts/videoTest_1763621015830",
            description: "3420번 버스는 어디로 가나요? 🚌"
        ),
        // 까치
        ShortFormVideo(
            filePath:  "/data/posts/videoTest_1763630924583",
            description: "까치 영상을 찍어보았습니다."
        ),
        // 석양
        ShortFormVideo(
            filePath: "/data/posts/videoTest_1763713895739",
            description: "해가 정말 짧아졌어요...겨울이 다가오고 있음을 느낍니다.."
        ),
        // 관악산
        ShortFormVideo(
            filePath:  "/data/posts/videoTest_1763632429638",
            description: "산에서 불 나는 것 같지 않아요? 타임랩스로 찍어보았습니다."
        ),
        // 주토피아
        ShortFormVideo(
            filePath:  "/data/posts/videoTest_1763646870669",
            description: "곧 있으면 주토피아 2가 개봉한다는데...1편을 재미있게 본 기억이 있네요.\n2편은 과연?"
        ),
        // 지하철 한강
        ShortFormVideo(
            filePath:  "/data/posts/videoTest_1763647064417",
            description: "지하철을 타고 한강을 지나갈 때 잠시 창밖을 바라보며 잠시 핸드폰을 내려놓아보세요"
        )
    ]
    
    // 현재 스크롤 위치(비디오 ID) 추적
    @State private var currentVideoID: UUID?
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(videos) { video in
                        FeedVideoCell(video: video,
                                      bottomInset: proxy.safeAreaInsets.bottom,
                                      currentVideoID: $currentVideoID)
                            .containerRelativeFrame([.horizontal, .vertical])
                            .id(video.id)
                    }
                }
                .ignoresSafeArea()
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentVideoID)
            .ignoresSafeArea()
            .background(Color.black)
            .onAppear {
                if currentVideoID == nil {
                    currentVideoID = videos.first?.id
                }
            }
        }
    }
}


