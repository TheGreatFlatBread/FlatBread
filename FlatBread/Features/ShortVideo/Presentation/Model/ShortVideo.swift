//
//  ShortVideo.swift
//  FlatBread
//
//  Created by 김민성 on 11/23/25.
//

import AVFoundation
import Foundation

final class ShortVideo: Identifiable, Hashable {
    
    static func == (lhs: ShortVideo, rhs: ShortVideo) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // 더미 URL.
    // 실제 URL은 resourceLoaderDelegate에서 filePath를 Network Layer에 넘겨줌.
    // AVPlayer가 사용할 URL을 직접 사용하지 않고 Delegate에 위임하도록 가짜 URL 커스텀
    static let dummyURL = URL(string: "custom-https://www.dummyURL.com/sample/video.mp4")!
    
    let id: String
    let moimID: String
    let title: String
    let price: Int
    let content: String
    let createdDate: String?
    let creator: CreatorResponseDTO?
    let files: [String]
    let likes: [String]
    let likes2: [String]
    let buyers: [String]
    let hashTags: [String]
    let commentCount: Int
    let geoLocation: GeoLocationResponseDTO?
    let distance: Double?
    
    let avURLAsset: AVURLAsset
    let resourceLoaderDelegate = CustomResourceLoaderDelegate()
    
    
    init(
        id: String,
        moimID: String,
        title: String,
        price: Int,
        content: String,
        createdDate: String?,
        creator: CreatorResponseDTO?,
        files: [String],
        likes: [String],
        likes2: [String],
        buyers: [String],
        hashTags: [String],
        commentCount: Int,
        geoLocation: GeoLocationResponseDTO?,
        distance: Double?
    ) {
        self.id = id
        self.moimID = moimID
        self.title = title
        self.price = price
        self.content = content
        self.createdDate = createdDate
        self.creator = creator
        self.files = files
        self.likes = likes
        self.likes2 = likes2
        self.buyers = buyers
        self.hashTags = hashTags
        self.commentCount = commentCount
        self.geoLocation = geoLocation
        self.distance = distance
        
        let filePath = files.first ?? ""
        self.avURLAsset = AVURLAsset(url: Self.dummyURL)
        let queue = DispatchQueue(label: "com.flatBread.resourceLoader.\(filePath)")
        resourceLoaderDelegate.videoFilePath = filePath
        self.avURLAsset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: queue)
    }
    
}


extension PostResponseDTO {
    
    var asShortVideoItem: ShortVideo {
        return ShortVideo(
            id: self.post_id ?? "",
            moimID: self.category ?? "",
            title: self.title ?? "",
            price: self.price ?? 0,
            content: self.content ?? "",
            createdDate: self.createdAt,
            creator: self.creator,
            files: self.files,
            likes: self.likes,
            likes2: self.likes2,
            buyers: self.buyers,
            hashTags: self.hashTags,
            commentCount: self.comment_count ?? 0,
            geoLocation: self.geolocation,
            distance: self.distance
        )
    }
    
    // short Video dummy data
    static var shortVideosDummy: [PostResponseDTO] {
        return [
            PostResponseDTO(
                post_id: "a1f4b2e9c8d5f7a0b3e6d2c8f1a5e0b4",
                category: "random_post_id",
                title: "",
                price: 0,
                content: "3420번 버스는 어디로 가나요? 🚌",
                value1: nil, value2: nil, value3: nil, value4: nil, value5: nil, value6: nil, value7: nil, value8: nil, value9: nil, value10: nil,
                createdAt: "2025-11-21T10:30:44.362Z",
                creator: nil,
                files: ["/data/posts/videoTest_1763621015830"],
                likes: ["abcd", "efgh", "ijkl", "mnop"],
                likes2: [],
                buyers: [],
                hashTags: ["FBP_shortVideo"],
                comment_count: 35,
                geolocation: nil,
                distance: nil
            ),
            PostResponseDTO(
                post_id: "9e8d7c6b5a4f3e2d1c0b9a8f7e6d5c4b",
                category: "random_post_id",
                title: "",
                price: 0,
                content: "까치 영상을 찍어보았습니다.",
                value1: nil, value2: nil, value3: nil, value4: nil, value5: nil, value6: nil, value7: nil, value8: nil, value9: nil, value10: nil,
                createdAt: "2025-11-21T10:30:44.362Z",
                creator: nil,
                files: ["/data/posts/videoTest_1763630924583"],
                likes: ["abcd", "efgh", "ijkl", "mnop"],
                likes2: [],
                buyers: [],
                hashTags: ["FBP_shortVideo"],
                comment_count: 35,
                geolocation: nil,
                distance: nil
            ),
            PostResponseDTO(
                post_id: "b5a8c1f4e7d2a0f3e6d9c2b8a5f1e7d0",
                category: "random_post_id",
                title: "",
                price: 0,
                content: "해가 정말 짧아졌어요...겨울이 다가오고 있음을 느낍니다..",
                value1: nil, value2: nil, value3: nil, value4: nil, value5: nil, value6: nil, value7: nil, value8: nil, value9: nil, value10: nil,
                createdAt: "2025-11-21T10:30:44.362Z",
                creator: nil,
                files: ["/data/posts/videoTest_1763713895739"],
                likes: ["abcd", "efgh", "ijkl", "mnop"],
                likes2: [],
                buyers: [],
                hashTags: ["FBP_shortVideo"],
                comment_count: 35,
                geolocation: nil,
                distance: nil
            ),
            PostResponseDTO(
                post_id: "d9c0b8a1f4e7d2a5f1e7d0b4a8c2f6e9",
                category: "random_post_id",
                title: "",
                price: 0,
                content: "산에서 불 나는 것 같지 않아요? 타임랩스로 찍어보았습니다.",
                value1: nil, value2: nil, value3: nil, value4: nil, value5: nil, value6: nil, value7: nil, value8: nil, value9: nil, value10: nil,
                createdAt: "2025-11-21T10:30:44.362Z",
                creator: nil,
                files: ["/data/posts/videoTest_1763632429638"],
                likes: ["abcd", "efgh", "ijkl", "mnop"],
                likes2: [],
                buyers: [],
                hashTags: ["FBP_shortVideo"],
                comment_count: 35,
                geolocation: nil,
                distance: nil
            ),
            PostResponseDTO(
                post_id: "3c7b2a8f4e1d9c5b0a6f8e2d7c4b1a5f",
                category: "random_post_id",
                title: "",
                price: 0,
                content: "곧 있으면 주토피아 2가 개봉한다는데...1편을 재미있게 본 기억이 있네요.\n2편은 과연?",
                value1: nil, value2: nil, value3: nil, value4: nil, value5: nil, value6: nil, value7: nil, value8: nil, value9: nil, value10: nil,
                createdAt: "2025-11-21T10:30:44.362Z",
                creator: nil,
                files: ["/data/posts/videoTest_1763646870669"],
                likes: ["abcd", "efgh", "ijkl", "mnop"],
                likes2: [],
                buyers: [],
                hashTags: ["FBP_shortVideo"],
                comment_count: 35,
                geolocation: nil,
                distance: nil
            ),
            PostResponseDTO(
                post_id: "f8e2d7c4b1a5f3e9d0c6b7a2f5e1d8c3",
                category: "random_post_id",
                title: "",
                price: 0,
                content: "지하철을 타고 한강을 지나갈 때 잠시 창밖을 바라보며 잠시 핸드폰을 내려놓아보세요",
                value1: nil, value2: nil, value3: nil, value4: nil, value5: nil, value6: nil, value7: nil, value8: nil, value9: nil, value10: nil,
                createdAt: "2025-11-21T10:30:44.362Z",
                creator: nil,
                files: ["/data/posts/videoTest_1763647064417"],
                likes: ["abcd", "efgh", "ijkl", "mnop"],
                likes2: [],
                buyers: [],
                hashTags: ["FBP_shortVideo"],
                comment_count: 35,
                geolocation: nil,
                distance: nil
            ),
            PostResponseDTO(
                post_id: "8f5c3b9e2d6a7f1e4d0c9b6a3f8e5d2c",
                category: "random_post_id",
                title: "",
                price: 0,
                content: "붉은 노을...",
                value1: nil, value2: nil, value3: nil, value4: nil, value5: nil, value6: nil, value7: nil, value8: nil, value9: nil, value10: nil,
                createdAt: "2025-11-21T10:30:44.362Z",
                creator: nil,
                files: ["/data/posts/videoTest_1763868195996"],
                likes: ["abcd", "efgh", "ijkl", "mnop"],
                likes2: [],
                buyers: [],
                hashTags: ["FBP_shortVideo"],
                comment_count: 35,
                geolocation: nil,
                distance: nil
            ),
            PostResponseDTO(
                post_id: "a1e4d7c0b3f6a9e2d5c8b1f4a7e0d3c6",
                category: "random_post_id",
                title: "",
                price: 0,
                content: "버클리대학교는 학교 도서관에 공룡 화석을 전시해 둔답니다...클라스 무엇..?",
                value1: nil, value2: nil, value3: nil, value4: nil, value5: nil, value6: nil, value7: nil, value8: nil, value9: nil, value10: nil,
                createdAt: "2025-11-21T10:30:44.362Z",
                creator: nil,
                files: ["/data/posts/videoTest_1763868555117"],
                likes: ["abcd", "efgh", "ijkl", "mnop"],
                likes2: [],
                buyers: [],
                hashTags: ["FBP_shortVideo"],
                comment_count: 35,
                geolocation: nil,
                distance: nil
            ),
            PostResponseDTO(
                post_id: "d6c9b2f5a8e1d4c7b0f3a6e9d2c5b8a1",
                category: "random_post_id",
                title: "",
                price: 0,
                content: "iOS 개발자(지망생)의 구글 캠퍼스 탐방기\n최근에 구글이 에어드랍도 연동되도록 자체적으로 기술을 개발했다던데...",
                value1: nil, value2: nil, value3: nil, value4: nil, value5: nil, value6: nil, value7: nil, value8: nil, value9: nil, value10: nil,
                createdAt: "2025-11-21T10:30:44.362Z",
                creator: nil,
                files: ["/data/posts/videoTest_1763869613105"],
                likes: ["abcd", "efgh", "ijkl", "mnop"],
                likes2: [],
                buyers: [],
                hashTags: ["FBP_shortVideo"],
                comment_count: 35,
                geolocation: nil,
                distance: nil
            ),
            PostResponseDTO(
                post_id: "2b9f4a7e0d3c6b9f1a4e7d0c3b6f8a5e",
                category: "random_post_id",
                title: "",
                price: 0,
                content: "윙가아아르디움 레비오우사\n여기는 유니버설 스튜디오 할리우드입니다.",
                value1: nil, value2: nil, value3: nil, value4: nil, value5: nil, value6: nil, value7: nil, value8: nil, value9: nil, value10: nil,
                createdAt: "2025-11-21T10:30:44.362Z",
                creator: nil,
                files: ["/data/posts/videoTest_1763869813789"],
                likes: ["abcd", "efgh", "ijkl", "mnop"],
                likes2: [],
                buyers: [],
                hashTags: ["FBP_shortVideo"],
                comment_count: 35,
                geolocation: nil,
                distance: nil
            ),
            PostResponseDTO(
                post_id: "c4b7a0e3d6c9b2f5a8e1d4c7b0f3a6e9",
                category: "random_post_id",
                title: "",
                price: 0,
                content: "유럽여행(스위스) 동행 급구!!🇨🇭🏔️\n일정에 따라 인근 국가들도 방문할 수 있음",
                value1: nil, value2: nil, value3: nil, value4: nil, value5: nil, value6: nil, value7: nil, value8: nil, value9: nil, value10: nil,
                createdAt: "2025-11-21T10:30:44.362Z",
                creator: nil,
                files: ["/data/posts/videoTest_1763874928744"],
                likes: ["abcd", "efgh", "ijkl", "mnop"],
                likes2: [],
                buyers: [],
                hashTags: ["FBP_shortVideo"],
                comment_count: 35,
                geolocation: nil,
                distance: nil
            ),
            PostResponseDTO(
                post_id: "e9d0c3b6f8a5e1d4c7b0f3a6e9d2c5b8",
                category: "random_post_id",
                title: "",
                price: 0,
                content: "유럽여행(스위스) 동행 급구!!🇨🇭🏔️\n융프라우요흐 코스 포함",
                value1: nil, value2: nil, value3: nil, value4: nil, value5: nil, value6: nil, value7: nil, value8: nil, value9: nil, value10: nil,
                createdAt: "2025-11-21T10:30:44.362Z",
                creator: nil,
                files: ["/data/posts/videoTest_1763875537750"],
                likes: ["abcd", "efgh", "ijkl", "mnop"],
                likes2: [],
                buyers: [],
                hashTags: ["FBP_shortVideo"],
                comment_count: 35,
                geolocation: nil,
                distance: nil
            ),
        ]
        
        
        
    }
    
}
