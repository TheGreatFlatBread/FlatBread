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
                RecommendMoimsList(moims: viewModel.recommendMoims)
                MyJoinedMoimsList(myMoims: viewModel.myMoims)
            }
        }
        .onAppear {
            viewModel.loadMoims()
        }
    }
}

private struct RecommendMoimsList: View {
    let moims: [MyMoimViewUIModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "요즘 뜨는 모임")
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(moims) { item in
                        MyMoimCell(moim: item)
                            .padding()
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct MyJoinedMoimsList: View {
    let myMoims: [MyMoimViewUIModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "가입한 모임")

            if myMoims.isEmpty {
                EmptyMyMoimView()
            } else {
                List(myMoims) { moim in
                    MyMoimCell(moim: moim) {
                        print(moim.title ?? "이름 없음")
                    }
                    .frame(height: 80)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollDisabled(true)
                .frame(height: CGFloat(myMoims.count) * 92)
            }
        }
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title2.bold())
            .foregroundStyle(.primary)
            .textCase(nil)
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 8)
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
