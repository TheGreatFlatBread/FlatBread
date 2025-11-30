//
//  MoimCardView.swift
//  FlatBread
//
//  Created by 김민성 on 11/9/25.
//

import NMapsGeometry
import SwiftUI

struct MoimCardView: View {
    let moimModel: MoimMapUIModel
    let isFocusing: Bool
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(url: moimModel.imageUrl ?? "",
                        displayMode: .thumbnail(CGSize(width: 300, height: 150)))
            { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .frame(width: 300, height: 150)
            
            LinearGradient(
                colors: [.clear, .black],
                startPoint: .center,
                endPoint: .bottom
            )
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(moimModel.category)
                        .font(.system(size: 11))
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.brown.opacity(0.8))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Text("\(Int.random(in: 10...30))명")
                        .font(.system(size: 11))
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                }
                
                Text(moimModel.name)
                    .font(.system(size: 15))
                    .fontWeight(.bold)
                
                HStack {
                    Spacer()
                    Text(moimModel.locationName ?? "위치 정보 없음")
                }
                .font(.system(size: 11))
                .opacity(0.8)
            }
            .padding(.all, 12)
            .foregroundColor(.white)
        }
        .frame(width: 300, height: 150)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isFocusing ? .yellow : Color.clear, lineWidth: 3)
        )
        .animation(.default, value: isFocusing)
    }
}


import CoreLocation

#Preview {
    let seSACMoim = MoimMapUIModel(
        id: "1",
        name: "새싹에서 공부하는 모임",
        category: "공부",
        currentMembers: 8,
        maxMembers: 12,
        location: .init(lat: 37.517677, lng: 126.886442),
        locationName: "테스트 지역",
        imageUrl: "https://images.unsplash.com/photo-1680022087238-eafecd5a8933?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb2ZmZWUlMjBtZWV0aW5nJTIwcGVvcGxlfGVufDF8fHx8MTc2MjM0MDE1MXww&ixlib=rb-4.1.0&q=80&w=1080",
    )
    
    MoimCardView(moimModel: seSACMoim, isFocusing: true)
}
