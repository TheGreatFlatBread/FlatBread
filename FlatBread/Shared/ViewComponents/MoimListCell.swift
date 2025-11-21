//
//  MoimListCell.swift
//  FlatBread
//
//  Created by 김민성 on 11/18/25.
//

import SwiftUI

struct MoimListCell: View {
    
    @Binding var moim: MoimSearchResultUIModel
    
    private let imageSideLength: CGFloat = 70.0
    private let clipShape = RoundedRectangle(cornerRadius: 15)
    
    var body: some View {
        HStack(spacing: 14) {
            RemoteImage(
                url: moim.imageURL ?? "",
                displayMode: .thumbnail(CGSize(width: 100, height: 100))
            ) {
                Color.gray
            } content: { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .frame(width: imageSideLength, height: imageSideLength)
            .cornerRadius(14)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(moim.title ?? "")
                    .lineLimit(1)
                    .font(.system(size: 14, weight: .bold))
                
                Spacer()
                    .frame(height: 3)
                
                HStack {
                    Text(moim.content)
                        .lineLimit(1)
                        .font(.system(size: 13))
                    
                }
                
                HStack {
                    Text(moim.category.rawValue)
                        .font(.system(size: 12))
                        .padding(.vertical, 5)
                        .padding(.horizontal, 9)
                        .background(.white)
                        .clipShape(clipShape)
                    
                    Label(moim.location, systemImage: "map")
                        .font(.system(size: 12))
                    
                    Label("\(moim.member.count)명", systemImage: "person.2")
                        .font(.system(size: 12))
                }
                .frame(height: 30)
                .padding(4)
            }
        }
    }
}

#Preview {
    @Previewable @State var dto = PostResponseDTO(
        post_id: "1234",
        category: MoimCategory.culturePerformancesFestivals.rawValue,
        title: "제목이 들어갈 위치, 여기는 제목이 들어갈 위치입니다.",
        price: 25000,
        content: "모임에 대한 간단한 소개글이 들어갈 위치. 내용이 길어지면 잘릴 수도 있음. \n 여러 줄 가능성 있음",
        value1: "서울 관악구",
        value2: nil, value3: nil, value4: nil, value5: nil, value6: nil, value7: nil, value8: nil, value9: nil, value10: nil,
        createdAt: "9999-10-19T03:05:03.422Z",
        creator: nil,
        files: [],
        likes: [],
        likes2: ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p"],
        buyers: [],
        hashTags: [],
        comment_count: 0,
        geolocation: nil,
        distance: nil
    ).asSearchResultUIModel!
    MoimListCell(moim: $dto)
}
