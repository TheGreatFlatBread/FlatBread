//
//  MainMapSearchBar.swift
//  FlatBread
//
//  Created by 김민성 on 11/6/25.
//

import SwiftUI

struct MainMapSearchBar: View {
    
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("모임을 검색해보세요", text: $searchText)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(.infinity)
        .shadow(radius: 8)
    }
}

#Preview {
    let previewSearchText: Binding<String> = Binding.constant("검색어")
    MainMapSearchBar(searchText: previewSearchText)
}
