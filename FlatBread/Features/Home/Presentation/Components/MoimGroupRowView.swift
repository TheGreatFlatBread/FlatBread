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
                RemoteImage(
                    url: item.imageURL,
                    displayMode: .thumbnail(CGSize(width: 72, height: 72))
                ) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                .frame(width: 72, height: 72)
                .background(Color(uiColor: .systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    Group {
                        EmptyView()
                    }
                )
                
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
