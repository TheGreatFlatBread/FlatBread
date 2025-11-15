//
//  MyMoimCell.swift
//  FlatBread
//
//  Created by 서준일 on 11/6/25.
//

import SwiftUI

struct MyMoimCell: View {
    let moim: MyMoimViewUIModel
    @State private var isLike: Bool = false
    
    var onTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 6) {
            thumbnail
            content
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap?()
                }
        }
    }

    // MARK: - Thumbnail
    private var thumbnail: some View {
        Group {
            if let thumbnailURL = moim.imageURLs.first,
               let url = URL(string: thumbnailURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .overlay {
                                ProgressView()
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.3))
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 80, height: 80)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .aspectRatio(1, contentMode: .fit)
            }
        }
        .overlay(alignment: .bottomLeading) {
            likeButton
        }
    }

    // MARK: - Content
    private var content: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(moim.title ?? "")
                .lineLimit(1)
                .font(.title3.bold())

            Text(moim.content ?? "")
                .lineLimit(1)
                .font(.body)

            metaInfo
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Meta Info
    private var metaInfo: some View {
        HStack(spacing: 4) {
            if let category = moim.category {
                Text(category)
            }

            if moim.category != nil && moim.value5 != nil {
                Text("·")
            }

            if let location = moim.value5 {
                Text(location)
            }

            if moim.value5 != nil && moim.value4 != nil {
                Text("·")
            }

            if let memberCount = moim.value4 {
                Text("멤버 \(memberCount)")
            }
        }
        .font(.body)
        .foregroundStyle(.secondary)
    }

    // MARK: - Like Button
    private var likeButton: some View {
        Image(systemName: isLike ? "heart.fill" : "heart")
            .font(.system(size: 24))
            .foregroundStyle(.white)
            .padding(8)
            .contentShape(Circle())
            .buttonWrapper {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isLike.toggle()
                }
            }
    }
}

#Preview {
    MyMoimCell(moim: MyMoimViewUIModel.getDummy())
        .frame(height: 80)
    
    MyMoimCell(moim: MyMoimViewUIModel.getDummy()) {
        print("클릭")
    }
}
