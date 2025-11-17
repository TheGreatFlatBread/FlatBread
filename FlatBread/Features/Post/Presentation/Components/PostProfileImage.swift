//
//  PostProfileImage.swift
//  FlatBread
//
//  Created by hwan on 11/16/25.
//

import SwiftUI

struct PostProfileImage: View {
    let profileImageURL: String
    
    var body: some View {
        Group {
            if let url = URL(string: profileImageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                }
            } else {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.orange)
                    }
            }
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())
    }
}
