//
//  ScheduleCardView.swift
//  FlatBread
//
//  Created by hwan on 11/16/25.
//

import SwiftUI

struct ScheduleCardView: View {
    let schedule: ScheduleUIModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 날짜 아이콘
                VStack(spacing: 4) {
                    Text(schedule.date.formatted(.dateTime.month(.abbreviated)))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.orange)
                        .textCase(.uppercase)

                    Text(schedule.date.formatted(.dateTime.day()))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.primary)
                }
                .frame(width: 56)
                .padding(.vertical, 12)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // 일정 정보
                VStack(alignment: .leading, spacing: 6) {
                    Text(schedule.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Label {
                            Text(schedule.date.formatted(.dateTime.hour().minute()))
                                .font(.system(size: 13))
                        } icon: {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(.secondary)

                        Circle()
                            .fill(Color.secondary.opacity(0.4))
                            .frame(width: 3, height: 3)

                        Label {
                            Text("\(schedule.participantCount)/\(schedule.maxParticipants)명")
                                .font(.system(size: 13))
                        } icon: {
                            Image(systemName: "person.2")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(.secondary)
                    }

                    if let location = schedule.location {
                        Label {
                            Text(location)
                                .font(.system(size: 13))
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: "mappin.circle")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(ScheduleUIModel.mocks) { schedule in
            ScheduleCardView(schedule: schedule) {
                print("Tapped: \(schedule.title)")
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
