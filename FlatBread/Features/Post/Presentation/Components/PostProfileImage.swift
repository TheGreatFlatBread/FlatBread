//
//  PostProfileImage.swift
//  FlatBread
//
//  Created by hwan on 11/16/25.
//

import SwiftUI

struct PostProfileImage: View {
    let profileImageURL: String?
    let name: String?
    let size: CGFloat

    init(
        profileImageURL: String?,
        name: String? = nil,
        size: CGFloat = 32
    ) {
        self.profileImageURL = profileImageURL
        self.name = name
        self.size = size
    }

    var body: some View {
        Group {
            if let profileImageURL = profileImageURL,
               !profileImageURL.isEmpty {
                RemoteImage(
                    url: profileImageURL,
                    displayMode: .thumbnail(CGSize(width: size * 2, height: size * 2))
                ) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            } else {
                placeholderView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var placeholderView: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                if let name = name, let firstLetter = name.first {
                    Text(String(firstLetter))
                        .font(.system(size: size * 0.4, weight: .semibold))
                        .foregroundStyle(.orange)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.45))
                        .foregroundStyle(Color.orange)
                }
            }
    }
}
