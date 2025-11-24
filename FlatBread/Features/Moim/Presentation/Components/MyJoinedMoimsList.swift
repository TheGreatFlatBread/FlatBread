//
//  MyJoinedMoimsList.swift
//  FlatBread
//
//  Created by 서준일 on 11/6/25.
//

import SwiftUI

struct MyJoinedMoimsList: View {
    let myMoims: [MoimSearchResultUIModel]
    let isLoading: Bool
    let hasMoreData: Bool
    let loadMore: () -> Void
    let onMoimTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "가입한 모임")

            if myMoims.isEmpty && !isLoading {
                EmptyMyMoimView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(myMoims) { moim in
                            MoimListCell(moim: .constant(moim))
                                .frame(height: 80)
                                .padding(.horizontal, 16)
                                .onTapGesture {
                                    onMoimTap(moim.id)
                                }
                                .onAppear {
                                    // 마지막 아이템이 보이면 다음 페이지 로드
                                    if moim.id == myMoims.last?.id && hasMoreData && !isLoading {
                                        loadMore()
                                    }
                                }
                        }

                        // 로딩 인디케이터
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding()
                        }
                    }
                    .padding(.vertical, 6)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

#Preview {
    MyJoinedMoimsList(
        myMoims: [],
        isLoading: false,
        hasMoreData: true,
        loadMore: {
            print("Load more")
        },
        onMoimTap: { moimId in
            print("Moim tapped: \(moimId)")
        }
    )
}
