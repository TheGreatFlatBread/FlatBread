//
//  SchedulePicker.swift
//  FlatBread
//
//  Created by hwan on 11/16/25.
//

import SwiftUI

struct SchedulePicker: View {

    @Binding var scheduleDate: Date
    @Binding var scheduleTitle: String
    @Binding var scheduleLocation: String
    @Binding var maxParticipants: Int
    @Binding var showSchedulePicker: Bool
    @Binding var hasSchedule: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("일정 제목")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)

                        TextField("예: 정기 모임", text: $scheduleTitle)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6).opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("날짜 및 시간")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 20)

                        DatePicker(
                            "일정 날짜 및 시간",
                            selection: $scheduleDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                        .padding(.horizontal, 20)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("장소 (선택)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)

                        TextField("예: 강남역 스타벅스", text: $scheduleLocation)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6).opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("최대 참여자")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)

                        Stepper(value: $maxParticipants, in: 1...100) {
                            Text("\(maxParticipants)명")
                                .font(.system(size: 16))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("일정 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSchedulePicker = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        hasSchedule = true
                        showSchedulePicker = false
                    } label: {
                        Text("추가")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}
