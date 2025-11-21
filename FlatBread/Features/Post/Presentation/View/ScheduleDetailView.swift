//
//  ScheduleDetailView.swift
//  FlatBread
//
//  Created by hwan on 11/16/25.
//

import SwiftUI
import MapKit

struct ScheduleDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let schedule: ScheduleUIModel

    @State private var isParticipating = false
    @State private var commentText = ""
    @State private var region: MKCoordinateRegion

    let participants = MemberUIModel.mocks
    let comments: [CommentUIModel] = CommentUIModel.getDummies()

    init(schedule: ScheduleUIModel) {
        self.schedule = schedule
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5137, longitude: 126.8965),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    ScheduleDetailView.HeaderImage()
                    VStack(spacing: 24) {
                        ScheduleDetailView.ScheduleInfo(
                            title: schedule.title,
                            description: schedule.description,
                            date: schedule.date.formatted(date: .long, time: .omitted),
                            time: schedule.date.formatted(date: .omitted, time: .shortened),
                            location: schedule.location,
                            participantCount: schedule.participantCount,
                            maxCount: schedule.maxParticipants
                        )
                        
                        ScheduleDetailView.ParticipantButton(isParticipating: $isParticipating)
                        
                        Divider()
                        
                        ScheduleDetailView.MapSection(
                            region: region,
                            location: schedule.location
                        )
                        
                        Divider()
                        
                        ScheduleDetailView.ParticipantSection(
                            participantCount: schedule.participantCount,
                            participant: Array(participants)
                        )
                        
                        Divider()
                        
                        ScheduleDetailView.CommentSection(
                            commentText: $commentText,
                            commentList: comments
                        )
                    }
                    .padding(.bottom, 100)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarItems
            }
        }
    }
    
    @ToolbarContentBuilder
    var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
            }
        }
    }
}

extension ScheduleDetailView {
    struct HeaderImage: View {
        var body: some View {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 200)
                .overlay {
                    Image(systemName: "calendar")
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.5))
                }
        }
    }

    struct ScheduleInfo: View {
        let title: String
        let description: String?
        let date: String
        let time: String
        let location: String?
        let participantCount: Int
        let maxCount: Int
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)
                
                InfoRow(icon: "calendar", title: "날짜", value: date)
                InfoRow(icon: "clock", title: "시간", value: time)
                if let location {
                    InfoRow(icon: "mappin.circle", title: "장소", value: location)
                }
                InfoRow(icon: "person.2", title: "참여 인원", value: "\(participantCount)/\(maxCount)명")
                
                if let description = description {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "text.alignleft")
                                .font(.system(size: 16))
                                .foregroundStyle(.orange)
                                .frame(width: 24)
                            
                            Text("설명")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        Text(description)
                            .font(.system(size: 15))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }
    
    struct ParticipantButton: View {
        @Binding var isParticipating: Bool
        
        var body: some View {
            Button {
                withAnimation {
                    isParticipating.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isParticipating ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))

                    Text(isParticipating ? "참여 중" : "참여하기")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: isParticipating ? [Color.gray, Color.gray] : [Color.orange, Color.orange.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 16)
        }
    }
    
    struct MapSection: View {
        let region: MKCoordinateRegion
        let location: String?
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("위치")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 20)

//                Map(coordinateRegion: .constant(region), annotationItems: [MapAnnotation(coordinate: region.center)]) { annotation in
//                    MapMarker(coordinate: annotation.coordinate, tint: .orange)
//                }
//                .frame(height: 200)
//                .clipShape(RoundedRectangle(cornerRadius: 12))
//                .padding(.horizontal, 20)

                if let location {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.orange)

                        Text(location)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
        }
    }
    
    struct ParticipantSection: View {
        let participantCount: Int
        let participant: [MemberUIModel]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("참여 멤버")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("\(participantCount)명")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)

                VStack(spacing: 8) {
                    ForEach(participant, id: \.id) { member in
                        ParticipantRow(member: member)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
        }
    }
    
    struct CommentSection: View {
        @Binding var commentText: String
        let commentList: [CommentUIModel]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("댓글")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("\(commentList.count)개")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)

                VStack(spacing: 16) {
                    ForEach(commentList, id: \.id) { comment in
                        CommentRow(comment: comment)
                    }
                }
                .padding(.horizontal, 20)

                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.orange)
                        }

                    TextField("댓글을 입력하세요...", text: $commentText)
                        .font(.system(size: 14))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Button {
                        
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(commentText.isEmpty ? .gray : .orange)
                    }
                    .disabled(commentText.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
        }
    }
    
    struct InfoRow: View {
        let icon: String
        let title: String
        let value: String

        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.orange)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Text(value)
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)
                }

                Spacer()
            }
        }
    }

    struct ParticipantRow: View {
        let member: MemberUIModel

        var body: some View {
            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.orange)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(member.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)

                        if member.isLeader {
                            Text("모임장")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }

                    if let bio = member.bio {
                        Text(bio)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 8)
        }
    }

    struct CommentRow: View {
        let comment: CommentUIModel

        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.orange)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(comment.authorName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)

                        Text(comment.createdAt.formatted(.relative(presentation: .named)))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Text(comment.content)
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                }

                Spacer()
            }
        }
    }
}


#Preview {
    ScheduleDetailView(schedule: ScheduleUIModel.mock)
}
