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
            AsyncImage(url: URL(string: moimModel.imageUrl ?? "")) { image in
                return image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.5)
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
                    
                    Text("\(moimModel.currentMembers)/\(moimModel.maxMembers)명")
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
                    Text("위치가 들어감")
                    Spacer()
                    Text("몇km떨어짐?")
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
        imageUrl: "https://images.unsplash.com/photo-1680022087238-eafecd5a8933?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb2ZmZWUlMjBtZWV0aW5nJTIwcGVvcGxlfGVufDF8fHx8MTc2MjM0MDE1MXww&ixlib=rb-4.1.0&q=80&w=1080",
    )
    
    MoimCardView(moimModel: seSACMoim, isFocusing: true)
}
