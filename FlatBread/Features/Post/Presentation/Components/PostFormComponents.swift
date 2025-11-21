//
//  PostFormComponents.swift
//  FlatBread
//
//  Created by hwan on 11/20/25.
//

import SwiftUI

enum PostFormComponents {
    struct CategoryPicker: View {
        @Binding var selectedCategory: PostType

        var body: some View {
            VStack(alignment: .leading, spacing: 14) {
                Text("카테고리 선택")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach([PostType.free, .greeting, .schedule], id: \.self) { category in
                            let isSelected = selectedCategory == category
                            return Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategory = category
                                }
                            } label: {
                                Text(category.displayName)
                                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
                                    .background(
                                        Group {
                                            if isSelected {
                                                LinearGradient(
                                                    colors: [Color.orange, Color.orange.opacity(0.85)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            } else {
                                                Color(.systemGray6)
                                            }
                                        }
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    struct ContentEditor: View {
        @Binding var content: String

        var body: some View {
            VStack(alignment: .leading, spacing: 14) {
                Text("내용")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 20)

                TextEditor(text: $content)
                    .frame(height: 240)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGray6).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("게시글 내용을 입력하세요...")
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 24)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(.horizontal, 20)
            }
        }
    }

    struct Attachment: View {
        let icon: String
        let title: String
        let subTitle: String
        let isActive: Bool
        let action: () -> Void

        var body: some View {
            Button {
                action()
            } label: {
                HStack(spacing: 14) {
                    Circle().fill(
                        LinearGradient(
                            colors: isActive ? [Color.orange.opacity(0.8), Color.orange.opacity(0.5)] : [Color(.systemGray5), Color(.systemGray6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(isActive ? .white : .secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.primary)

                        Text(subTitle)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(Color(.systemGray6).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    struct ImagePreviewGrid: View {
        let imageURLs: [String]
        let onDelete: (Int) -> Void

        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(imageURLs.enumerated()), id: \.element) { index, url in
                        ZStack(alignment: .topTrailing) {
                            RemoteImage(
                                url: url,
                                displayMode: .thumbnail(CGSize(width: 120, height: 120))
                            ) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            Button {
                                onDelete(index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.white)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                            .offset(x: 6, y: -6)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 12)
        }
    }
}
