//
//  ProfileMenuButtonRow.swift
//  FlatBread
//
//  Created by 김민성 on 11/13/25.
//

import SwiftUI

struct ProfileMenuButtonRow: View {
    var title: String
    var isDestructive: Bool = false

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(isDestructive ? .red : .primary)
            Spacer()

            if !isDestructive {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(32)
    }
}

#Preview {
    ProfileMenuButtonRow(title: "프로필 항목 메뉴 버튼", isDestructive: false)
}
