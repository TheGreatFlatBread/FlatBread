//
//  PostMapperTests.swift
//  FlatBreadTests
//
//  Created by hwan on 11/16/25.
//

import Foundation
import Testing
@testable import FlatBread

@Suite("PostMapper Tests")
struct PostMapperTests {

    @Test("해시태그 파싱 - 일반 케이스")
    func test_parseHashtags_normal() {
        let content = "오늘도 파이팅! #영등포 #청취사 #새싹 #iOS #swift"
        let hashtags = PostMapper.parseHashtags(from: content)

        #expect(hashtags.count == 5)
        #expect(hashtags.contains("영등포"))
        #expect(hashtags.contains("청취사"))
        #expect(hashtags.contains("새싹"))
        #expect(hashtags.contains("iOS"))
        #expect(hashtags.contains("swift"))
    }

    @Test("해시태그 파싱 - 이모지 포함")
    func test_parseHashtags_withEmoji() {
        let content = "좋아요! #⭐️ #sesac #🌱"
        let hashtags = PostMapper.parseHashtags(from: content)

        #expect(hashtags.count == 3)
        #expect(hashtags.contains("⭐️"))
        #expect(hashtags.contains("sesac"))
        #expect(hashtags.contains("🌱"))
    }

    @Test("해시태그 파싱 - 해시태그 없음")
    func test_parseHashtags_none() {
        let content = "해시태그가 없는 텍스트입니다."
        let hashtags = PostMapper.parseHashtags(from: content)

        #expect(hashtags.isEmpty)
    }

    @Test("해시태그 파싱 - 연속된 해시태그")
    func test_parseHashtags_consecutive() {
        let content = "#첫번째#두번째#세번째"
        let hashtags = PostMapper.parseHashtags(from: content)

        #expect(hashtags.count == 3)
        #expect(hashtags.contains("첫번째"))
        #expect(hashtags.contains("두번째"))
        #expect(hashtags.contains("세번째"))
    }

    @Test("해시태그 제거 - 일반 케이스")
    func test_removeHashtags_normal() {
        let content = "오늘도 파이팅! #영등포 #청취사 #새싹"
        let cleaned = PostMapper.removeHashtags(from: content)

        #expect(cleaned == "오늘도 파이팅!")
        #expect(!cleaned.contains("#"))
    }

    @Test("해시태그 제거 - 중간에 해시태그")
    func test_removeHashtags_middle() {
        let content = "안녕하세요 #새싹 잘 부탁드립니다 #iOS"
        let cleaned = PostMapper.removeHashtags(from: content)

        #expect(cleaned == "안녕하세요 잘 부탁드립니다")
        #expect(!cleaned.contains("#"))
    }

    @Test("해시태그 제거 - 연속된 공백 정리")
    func test_removeHashtags_multipleSpaces() {
        let content = "텍스트 #태그1 #태그2 #태그3 끝"
        let cleaned = PostMapper.removeHashtags(from: content)

        #expect(cleaned == "텍스트 끝")
        #expect(!cleaned.contains("  ")) // 연속된 공백이 없어야 함
    }

    @Test("해시태그 제거 - 해시태그만 있는 경우")
    func test_removeHashtags_onlyHashtags() {
        let content = "#태그1 #태그2 #태그3"
        let cleaned = PostMapper.removeHashtags(from: content)

        #expect(cleaned.isEmpty || cleaned.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    // MARK: - PostUIModel Conversion Tests

    @Test("PostUIModel 변환 - FREE 타입")
    func test_toPostUIModel_freeType() {
        let dto = makePostDTO(
            postId: "post123",
            moimId: "moim123",
            postType: "FREE",
            content: "자유 게시판 글입니다 #자유 #게시판 #자유게시판",
            creatorId: "user123",
            creatorName: "김철수"
        )

        let uiModel = PostMapper.toPostUIModel(from: dto, currentUserId: "currentUser")

        #expect(uiModel != nil)
        #expect(uiModel?.id == "post123")
        #expect(uiModel?.moimId == "moim123")
        #expect(uiModel?.postType == .free)
        #expect(uiModel?.content == "자유 게시판 글입니다")
        #expect(uiModel?.hashtags.contains("자유게시판") == true)
        #expect(uiModel?.schedule == nil)
    }

    @Test("PostUIModel 변환 - GREETING 타입")
    func test_toPostUIModel_greetingType() {
        let dto = makePostDTO(
            postId: "post456",
            moimId: "moim123",
            postType: "GREETING",
            content: "안녕하세요! 새로 가입했습니다 #새싹 #가입인사",
            creatorId: "user456",
            creatorName: "이영희"
        )

        let uiModel = PostMapper.toPostUIModel(from: dto, currentUserId: "currentUser")

        #expect(uiModel != nil)
        #expect(uiModel?.postType == .greeting)
        #expect(uiModel?.content == "안녕하세요! 새로 가입했습니다")
        #expect(uiModel?.hashtags.contains("가입인사") == true)
    }

    @Test("PostUIModel 변환 - SCHEDULE 타입")
    func test_toPostUIModel_scheduleType() {
        let scheduleDate = ISO8601DateFormatter().string(from: Date())
        let dto = makeSchedulePostDTO(
            postId: "post789",
            moimId: "moim123",
            content: "모임 일정입니다 #모임 #일정 #모임일정",
            scheduleTitle: "주말 모임",
            scheduleDate: scheduleDate,
            maxParticipants: "10",
            participantCount: "3"
        )

        let uiModel = PostMapper.toPostUIModel(from: dto, currentUserId: "currentUser")

        #expect(uiModel != nil)
        #expect(uiModel?.postType == .schedule)
        #expect(uiModel?.content == "모임 일정입니다")
        #expect(uiModel?.hashtags.contains("모임일정") == true)
        #expect(uiModel?.schedule != nil)
        #expect(uiModel?.schedule?.id == "post789")
        #expect(uiModel?.schedule?.title == "주말 모임")
        #expect(uiModel?.schedule?.maxParticipants == 10)
        #expect(uiModel?.schedule?.participantCount == 3)
    }

    @Test("PostUIModel 변환 - 좋아요 정보")
    func test_toPostUIModel_likeInfo() {
        let dto = makePostDTO(
            postId: "post123",
            moimId: "moim123",
            postType: "FREE",
            content: "테스트 #자유게시판",
            creatorId: "user123",
            creatorName: "김철수",
            likes: ["currentUser", "user456", "user789"]
        )

        let uiModel = PostMapper.toPostUIModel(from: dto, currentUserId: "currentUser")

        #expect(uiModel?.likeCount == 3)
        #expect(uiModel?.isLiked == true)
    }

    @Test("PostUIModel 변환 - 북마크 정보")
    func test_toPostUIModel_bookmarkInfo() {
        let dto = makePostDTO(
            postId: "post123",
            moimId: "moim123",
            postType: "FREE",
            content: "테스트 #자유게시판",
            creatorId: "user123",
            creatorName: "김철수",
            likes2: ["currentUser"]
        )

        let uiModel = PostMapper.toPostUIModel(from: dto, currentUserId: "currentUser")

        #expect(uiModel?.isBookmarked == true)
    }

    @Test("ScheduleUIModel 변환 - 정상 케이스")
    func test_toScheduleUIModel_success() {
        let scheduleDate = ISO8601DateFormatter().string(from: Date())
        let dto = makeSchedulePostDTO(
            postId: "schedule123",
            moimId: "moim123",
            content: "일정입니다 #모임일정",
            scheduleTitle: "주말 모임",
            scheduleDate: scheduleDate,
            maxParticipants: "10",
            participantCount: "5",
            location: "강남역"
        )

        let scheduleModel = PostMapper.toScheduleUIModel(from: dto)

        #expect(scheduleModel != nil)
        #expect(scheduleModel?.id == "schedule123")
        #expect(scheduleModel?.title == "주말 모임")
        #expect(scheduleModel?.maxParticipants == 10)
        #expect(scheduleModel?.participantCount == 5)
        #expect(scheduleModel?.location == "강남역")
    }

    @Test("ScheduleUIModel 변환 - FREE 타입은 nil 반환")
    func test_toScheduleUIModel_freeTypeReturnsNil() {
        let dto = makePostDTO(
            postId: "post123",
            moimId: "moim123",
            postType: "FREE",
            content: "자유 게시판 #자유게시판",
            creatorId: "user123",
            creatorName: "김철수"
        )

        let scheduleModel = PostMapper.toScheduleUIModel(from: dto)

        #expect(scheduleModel == nil)
    }

    @Test("TempPostMoimModel 변환 - 정상 케이스")
    func test_toTempMoimModel_success() {
        let dto = makeMoimDTO(
            moimId: "moim123",
            name: "자라나라 새싹",
            category: "스터디",
            content: "새싹 모임입니다 #새싹 #스터디",
            memberCount: "10",
            maxMembers: "20",
            location: "문래동",
            latitude: 37.517677,
            longitude: 126.886442
        )

        let moimModel = PostMapper.toTempMoimModel(from: dto)

        #expect(moimModel != nil)
        #expect(moimModel?.id == "moim123")
        #expect(moimModel?.name == "자라나라 새싹")
        #expect(moimModel?.category == "스터디")
        #expect(moimModel?.description == "새싹 모임입니다")
        #expect(moimModel?.hashtags.count == 2)
        #expect(moimModel?.memberCount == 10)
        #expect(moimModel?.maxMembers == 20)
        #expect(moimModel?.location?.name == "문래동")
        #expect(moimModel?.location?.coordinate?.latitude == 37.517677)
    }

    @Test("TempPostMoimModel 변환 - 위치 정보 없음")
    func test_toTempMoimModel_noLocation() {
        let dto = makeMoimDTO(
            moimId: "moim123",
            name: "온라인 모임",
            category: "온라인",
            content: "온라인으로 진행합니다",
            memberCount: "5",
            maxMembers: "10"
        )

        let moimModel = PostMapper.toTempMoimModel(from: dto)

        #expect(moimModel != nil)
        #expect(moimModel?.location == nil)
    }

    @Test("RequestDTO 변환 - FREE 타입")
    func test_toRequestDTO_freeType() {
        let requestDTO = PostMapper.toRequestDTO(
            moimId: "moim123",
            postType: .free,
            content: "자유 게시판 글입니다 #자유",
            images: ["image1.jpg"],
            schedule: nil,
            location: nil
        )

        #expect(requestDTO.category == "moim123")
        #expect(requestDTO.value1 == "FREE")
        #expect(requestDTO.content == "자유 게시판 글입니다 #자유 #자유게시판")
        #expect(requestDTO.content?.contains("#자유게시판") == true)
        #expect(requestDTO.files.count == 1)
    }

    @Test("RequestDTO 변환 - SCHEDULE 타입")
    func test_toRequestDTO_scheduleType() {
        let scheduleDate = Date()
        let schedule = ScheduleData(
            title: "주말 모임",
            date: scheduleDate,
            location: "강남역",
            maxParticipants: 10
        )

        let requestDTO = PostMapper.toRequestDTO(
            moimId: "moim123",
            postType: .schedule,
            content: "일정입니다",
            images: [],
            schedule: schedule,
            location: (latitude: 37.5, longitude: 127.0)
        )

        #expect(requestDTO.category == "moim123")
        #expect(requestDTO.value1 == "SCHEDULE")
        #expect(requestDTO.content?.contains("#모임일정") == true)
        #expect(requestDTO.value2 == "주말 모임")
        #expect(requestDTO.value3 != nil) // ISO8601 date string
        #expect(requestDTO.value5 == "10")
        #expect(requestDTO.value6 == "0")
        #expect(requestDTO.value7 == "강남역")
        #expect(requestDTO.latitude == 37.5)
        #expect(requestDTO.longitude == 127.0)
    }

    private func makePostDTO(
        postId: String,
        moimId: String,
        postType: String,
        content: String,
        creatorId: String,
        creatorName: String,
        likes: [String] = [],
        likes2: [String] = []
    ) -> PostResponseDTO {
        return PostResponseDTO(
            post_id: postId,
            category: moimId,
            title: nil,
            price: nil,
            content: content,
            value1: postType,
            value2: nil,
            value3: nil,
            value4: nil,
            value5: nil,
            value6: nil,
            value7: nil,
            value8: nil,
            value9: nil,
            value10: nil,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            creator: CreatorResponseDTO(
                user_id: creatorId,
                nick: creatorName,
                profileImage: nil
            ),
            files: [],
            likes: likes,
            likes2: likes2,
            buyers: [],
            hashTags: [],
            comment_count: 0,
            geolocation: nil,
            distance: nil
        )
    }

    private func makeSchedulePostDTO(
        postId: String,
        moimId: String,
        content: String,
        scheduleTitle: String,
        scheduleDate: String,
        maxParticipants: String,
        participantCount: String,
        location: String? = nil
    ) -> PostResponseDTO {
        return PostResponseDTO(
            post_id: postId,
            category: moimId,
            title: nil,
            price: nil,
            content: content,
            value1: "SCHEDULE",
            value2: scheduleTitle,
            value3: scheduleDate,
            value4: nil,
            value5: maxParticipants,
            value6: participantCount,
            value7: location,
            value8: nil,
            value9: nil,
            value10: nil,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            creator: CreatorResponseDTO(
                user_id: "user123",
                nick: "작성자",
                profileImage: nil
            ),
            files: [],
            likes: [],
            likes2: [],
            buyers: [],
            hashTags: [],
            comment_count: 0,
            geolocation: nil,
            distance: nil
        )
    }

    private func makeMoimDTO(
        moimId: String,
        name: String,
        category: String,
        content: String,
        memberCount: String,
        maxMembers: String,
        location: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) -> PostResponseDTO {
        let geolocation: GeoLocationResponseDTO? = {
            if let lat = latitude, let lng = longitude {
                return GeoLocationResponseDTO(longitude: lng, latitude: lat)
            }
            return nil
        }()

        return PostResponseDTO(
            post_id: moimId,
            category: category,
            title: name,
            price: nil,
            content: content,
            value1: nil,
            value2: nil,
            value3: maxMembers,
            value4: memberCount,
            value5: location,
            value6: nil,
            value7: nil,
            value8: nil,
            value9: nil,
            value10: nil,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            creator: CreatorResponseDTO(
                user_id: "creator123",
                nick: "모임장",
                profileImage: nil
            ),
            files: [],
            likes: [],
            likes2: [],
            buyers: [],
            hashTags: [],
            comment_count: nil,
            geolocation: geolocation,
            distance: nil
        )
    }
}
