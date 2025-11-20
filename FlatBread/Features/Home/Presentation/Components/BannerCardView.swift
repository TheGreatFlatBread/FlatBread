//
//  BannerCardView.swift
//  FlatBread
//
//  Created by andev on 11/10/25.
//

import SwiftUI

struct BannerCardView: View {

    let item: BannerItem

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {

                // URL 기반 비동기 이미지 로딩
                RemoteImage(
                    url: item.imageURL,
                    displayMode: .thumbnail(CGSize(width: geo.size.width, height: geo.size.height)),
                    placeholder: {
                        Color(.systemGray5)
                            .overlay {
                                ProgressView()
                            }
                    },
                    imageService: DefaultImageService.shared,
                    content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(
                                width: geo.size.width,
                                height: geo.size.height
                            )
                            .clipped()
                    }
                )

                // 아래쪽 그라데이션
                LinearGradient(
                    colors: [.clear, .black.opacity(0.6)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                // 텍스트 영역
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.system(size: 20, weight: .bold))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(item.subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .opacity(0.8)
                }
                .foregroundStyle(.white)
                .padding(18)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .frame(height: 280)   // 카드 전체 높이
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

#Preview {
    BannerCardView(
        item: .init(
            id: "preview-post-id",
            imageURL: "https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=1200&q=80",
            title: "모임타이틀모임타이틀\n모이면 최저가에!",
            subtitle: "모임 전용 쿠폰 & 이벤트"
        )
    )
    .padding()
    .background(.black.opacity(0.1))
}
