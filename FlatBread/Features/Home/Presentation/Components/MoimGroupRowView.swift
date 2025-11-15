//
//  MoimGroupRowView.swift
//  FlatBread
//
//  Created by andev on 11/12/25.
//

import SwiftUI

struct MoimGroupRowView: View {
    
    let item: MoimGroupItem
    var onTap: ((MoimGroupItem) -> Void)? = nil
    
    var body: some View {
        Button {
            onTap?(item)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                AsyncImage(url: URL(string: item.imageURL)) { phase in
                    switch phase {
                    case .empty: Color(.systemGray5)
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .failure:
                        Color(.systemGray4).overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    @unknown default: Color(.systemGray5)
                    }
                }
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    Text(item.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text(item.category)
                        Circle().frame(width: 3, height: 3)
                        Text("멤버 \(item.memberCount)")
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                }
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

#Preview {
    MoimGroupRowView(
        item: .init(
            title: "콤플레이 배드민턴 모임🔥 신입모집🔥",
            subtitle: "함께 성장하는 2030 배드민턴 모임! 🏸",
            category: "운동/스포츠",
            memberCount: 251,
            imageURL: "https://images.unsplash.com/photo-1518604666860-9ed391f76460?auto=format&fit=crop&w=600&q=80"
        )
    )
    .padding()
}
