//
//  PostMapper.swift
//  FlatBread
//
//  Created by hwan on 11/16/25.
//

import Foundation

struct PostMapper {
    
    static func toPostUIModel(from dto: PostResponseDTO, currentUserId: String) -> PostUIModel? {
        guard let postId = dto.post_id,
              let moimId = dto.category,
              let content = dto.content,
              let createdAtString = dto.createdAt,
              let creator = dto.creator else {
            return nil
        }

        let createdAt = createdAtString.toDate() ?? Date()

        let hashtags = parseHashtags(from: content)

        guard let postType = PostType.fromHashtags(hashtags) else {
            return nil
        }

        let author = PostUIModel.Author(
            id: creator.user_id ?? UUID().uuidString,
            name: creator.nick ?? "알 수 없음",
            profileImageURL: creator.profileImage
        )

        let cleanedContent = removeHashtags(from: content)
        let schedule = mapSchedule(from: dto, postType: postType)
        let likeCount = dto.likes.count
        let isLiked = dto.likes.contains(currentUserId)

        return PostUIModel(
            id: postId,
            moimId: moimId,
            author: author,
            createdAt: createdAt,
            postType: postType,
            content: cleanedContent,
            hashtags: Array(hashtags.dropFirst()),
            images: dto.files,
            schedule: schedule,
            likeCount: likeCount,
            commentCount: dto.comment_count ?? 0,
            isBookmarked: dto.likes2.contains(currentUserId),
            isLiked: isLiked
        )
    }

    static func toScheduleUIModel(from dto: PostResponseDTO) -> ScheduleUIModel? {
        guard let scheduleId = dto.post_id,
              let content = dto.content else {
            return nil
        }

        let hashtags = parseHashtags(from: content)
        guard let postType = PostType.fromHashtags(hashtags),
              postType == .schedule else {
            return nil
        }

        guard let title = dto.value2,
              let dateString = dto.value3,
              let date = dateString.toDate() else {
            return nil
        }

        let locationName = dto.value7
        let maxParticipants = Int(dto.value5 ?? "0") ?? 0
        let participantCount = Int(dto.value6 ?? "0") ?? 0
        let description = dto.content

        return ScheduleUIModel(
            id: scheduleId,
            title: title,
            date: date,
            location: locationName,
            participantCount: participantCount,
            maxParticipants: maxParticipants,
            description: description
        )
    }

    static func parseHashtags(from content: String) -> [String] {
        let pattern = "#([^\\s#]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        let nsString = content as NSString
        let matches = regex.matches(in: content, range: NSRange(location: 0, length: nsString.length))
        return matches.compactMap { match -> String? in
            guard match.numberOfRanges > 1 else { return nil }
            let range = match.range(at: 1)
            return nsString.substring(with: range)
        }
    }

    static func removeHashtags(from content: String) -> String {
        let pattern = "#[^\\s#]+"
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return content
        }
        
        let range = NSRange(location: 0, length: content.utf16.count)
        let result = regex.stringByReplacingMatches(
            in: content,
            range: range,
            withTemplate: ""
        )

        return result
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func toTempMoimModel(from dto: PostResponseDTO) -> TempPostMoimModel? {
        guard let moimId = dto.post_id,
              let name = dto.title,
              let category = dto.category,
              let content = dto.content,
              let createdAtString = dto.createdAt,
              let creator = dto.creator else {
            return nil
        }

        let createdAt = createdAtString.toDate() ?? Date()
        
        let location: TempPostMoimModel.Location? = {
            if let locationName = dto.value5 {
                let coordinate: TempPostMoimModel.Coordinate? = {
                    if let geo = dto.geolocation,
                       let lat = geo.latitude,
                       let lng = geo.longitude {
                        return TempPostMoimModel.Coordinate(
                            latitude: lat,
                            longitude: lng
                        )
                    }
                    return nil
                }()
                return TempPostMoimModel.Location(
                    name: locationName,
                    coordinate: coordinate
                )
            }
            return nil
        }()

        let likeV2Count = dto.likes2.count
        let memberCount = likeV2Count
        let maxMembers = Int(dto.value3 ?? "100") ?? 100

        let hashtags = parseHashtags(from: content)
        let cleanedDescription = removeHashtags(from: content)

        return TempPostMoimModel(
            id: moimId,
            name: name,
            category: category,
            description: cleanedDescription,
            location: location,
            imageURLs: dto.files,
            memberCount: memberCount,
            maxMembers: maxMembers,
            hashtags: hashtags,
            createdAt: createdAt,
            creator: TempPostMoimModel.Creator(
                id: creator.user_id ?? "",
                name: creator.nick ?? "알 수 없음",
                profileImageURL: creator.profileImage
            ),
            memberIds: dto.likes2,
            membershipFee: 0
        )
    }

    private static func mapSchedule(from dto: PostResponseDTO, postType: PostType) -> ScheduleUIModel? {
        guard postType == .schedule else { return nil }
        
        guard let scheduleId = dto.post_id,
              let title = dto.value2,
              let dateString = dto.value3,
              let date = dateString.toDate() else {
            return nil
        }

        let maxParticipants = Int(dto.value5 ?? "0") ?? 0
        let participantCount = Int(dto.value6 ?? "0") ?? 0
        let location = dto.value7
        let description = dto.content

        return ScheduleUIModel(
            id: scheduleId,
            title: title,
            date: date,
            location: location,
            participantCount: participantCount,
            maxParticipants: maxParticipants,
            description: description
        )
    }

    /// UIModel에서 RequestDTO로 변환 (게시물 작성)
    static func toRequestDTO(
        moimId: String,
        postType: PostType,
        content: String,
        images: [String],
        schedule: ScheduleData?,
        location: (latitude: Double, longitude: Double)?
    ) -> PostUploadRequestDTO
    {
        let contentWithCategory = "\(content) \(postType.categoryHashtag)"

        var dto = PostUploadRequestDTO(
            category: moimId,
            title: nil,
            price: nil,
            content: contentWithCategory,
            value1: nil,
            value2: nil,
            value3: nil,
            value4: nil,
            value5: nil,
            value6: nil,
            value7: nil,
            value8: nil,
            value9: nil,
            value10: nil,
            files: images,
            longitude: location?.longitude ?? 0,
            latitude: location?.latitude ?? 0
        )

        // 일정 정보가 있으면 value 필드에 저장
        if let schedule = schedule, postType == .schedule {
            dto.value2 = schedule.title
            dto.value3 = schedule.date.toISO8601String()
            dto.value4 = schedule.date.formatted(date: .omitted, time: .shortened)
            dto.value5 = "\(schedule.maxParticipants)"
            dto.value6 = "0" // 초기 참여 인원
            dto.value7 = schedule.location
        }

        return dto
    }
}

struct ScheduleData {
    let title: String
    let date: Date
    let location: String?
    let maxParticipants: Int
}


struct CommentMapper {
    static func toUIModel(from dto: CommentResponseDTO) -> CommentUIModel? {
        guard let commentId = dto.commentID,
              let content = dto.content,
              let createdAtString = dto.createdAt,
              let creator = dto.creator else {
            return nil
        }

        let createdAt = createdAtString.toDate() ?? Date()

        return CommentUIModel(
            id: commentId,
            authorId: creator.user_id ?? "",
            authorName: creator.nick ?? "알 수 없음",
            profileImageURL: creator.profileImage,
            content: content,
            createdAt: createdAt,
            replies: []
        )
    }

    static func toUIModel(from dto: CommentReplyResponseDTO) -> CommentUIModel? {
        guard let commentId = dto.commentID,
              let content = dto.content,
              let createdAtString = dto.createdAt,
              let creator = dto.creator else {
            return nil
        }

        let createdAt = createdAtString.toDate() ?? Date.now

        let replies = dto.replies.compactMap { replyDTO in
            toUIModel(from: replyDTO)
        }

        return CommentUIModel(
            id: commentId,
            authorId: creator.user_id ?? "",
            authorName: creator.nick ?? "알 수 없음",
            profileImageURL: creator.profileImage,
            content: content,
            createdAt: createdAt,
            replies: replies
        )
    }
}

