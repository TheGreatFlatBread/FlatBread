//
//  MyMoimView.swift
//  FlatBread
//
//  Created by 서준일 on 11/6/25.
//

import SwiftUI

struct MyMoimView: View {
    @StateObject private var viewModel = MyMoimViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                RecommendSectionView(moims: viewModel.recommendMoims)
                MyJoinedSectionView(myMoims: viewModel.myMoims)
            }
        }
        .onAppear {
            viewModel.loadMoims()
        }
    }
}

private struct RecommendSectionView: View {
    let moims: [Moim]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle("요즘 뜨는 모임")
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(moims) { moim in
                        MyMoimCell(moim: moim)
                            .frame(width: 380, height: 80)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(height: 104)
        }
    }
}

private struct MyJoinedSectionView: View {
    let myMoims: [Moim]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle("가입한 모임")
            
            if myMoims.isEmpty {
                EmptyMyMoimView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(myMoims) { moim in
                        MyMoimCell(moim: moim) {
                            print(moim.title ?? "이름 없음")
                        }
                        .frame(height: 80)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }
}

private struct SectionTitle: View {
    let text: String
    
    init(_ text: String) { self.text = text }
    
    var body: some View {
        Text(text)
            .font(.title2.bold())
            .padding(.horizontal, 16)
            .padding(.top, 20)
    }
}

private struct EmptyMyMoimView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("가입한 모임이 없습니다")
                .font(.title3)
                .foregroundStyle(.gray)
            
            Text("새로운 모임에 참여해보세요")
                .font(.body)
                .foregroundStyle(.gray.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}


#Preview {
    MyMoimView()
}
