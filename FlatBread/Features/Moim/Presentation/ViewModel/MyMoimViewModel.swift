//
//  MyMoimViewModel.swift
//  FlatBread
//
//  Created by 서준일 on 11/7/25.
//

import Foundation
import Combine

final class MyMoimViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var recommendMoims: [MyMoimViewUIModel] = []
    @Published var myMoims: [MyMoimViewUIModel] = []

    // MARK: - Methods
    func loadMoims() {
        // 더미 데이터 로딩
        let dummies = MyMoimViewUIModel.getDummies()
        recommendMoims = dummies
        myMoims = dummies
    }
}
