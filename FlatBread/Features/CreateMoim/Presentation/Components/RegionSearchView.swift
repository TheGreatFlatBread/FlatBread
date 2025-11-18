//
//  RegionSearchView.swift
//  FlatBread
//
//  Created by andev on 11/18/25.
//

import SwiftUI

struct RegionSearchView: View {
    let allRegions: [String]
    let selected: String?
    let onSelect: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    
    private var filteredRegions: [String] {
        if searchText.isEmpty { return allRegions }
        return allRegions.filter { $0.localizedStandardContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredRegions, id: \.self) { region in
                    Button {
                        onSelect(region)
                        dismiss()
                    } label: {
                        HStack {
                            Text(region)
                            Spacer()
                            if region == selected {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("활동 지역 선택")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "시/군/구 검색"
            )
        }
    }
}
