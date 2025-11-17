//
//  ChatImageGridView.swift
//  FlatBread
//
//  Created by hwan on 11/14/25.
//

import SwiftUI

struct ChatImageGridCell: View {
    let imageURLs: [String]
    let maxWidth: CGFloat = 200
    @State private var showImageViewer = false
    @State private var selectedImageIndex = 0

    var body: some View {
        Group {
            switch imageURLs.count {
            case 1:
                singleImageView
            case 2:
                twoImagesView
            case 3:
                threeImagesView
            case 4:
                fourImagesView
            default:
                fiveOrMoreImagesView
            }
        }
        .fullScreenCover(isPresented: $showImageViewer) {
            ImagePagingViewer(imageURLs: imageURLs, selectedIndex: $selectedImageIndex, isPresented: $showImageViewer)
        }
    }
    
    private var singleImageView: some View {
        Button(action: {
            selectedImageIndex = 0
            showImageViewer = true
        }) {
            RemoteImage(url: imageURLs[0], displayMode: .thumbnail(CGSize(width: 200, height: 200))) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: maxWidth, height: maxWidth)
                    .clipped()
            }
            .frame(width: maxWidth, height: maxWidth)
            .background(Color(uiColor: .systemGray6))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var twoImagesView: some View {
        HStack(spacing: 4) {
            ForEach(Array(imageURLs.prefix(2).enumerated()), id: \.offset) { index, url in
                Button(action: {
                    selectedImageIndex = index
                    showImageViewer = true
                }) {
                    RemoteImage(url: url, displayMode: .thumbnail(CGSize(width: 200, height: 200))) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: (maxWidth - 4) / 2, height: maxWidth)
                            .clipped()
                    }
                    .frame(width: (maxWidth - 4) / 2, height: maxWidth)
                    .background(Color(uiColor: .systemGray6))
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private var threeImagesView: some View {
        HStack(spacing: 4) {
            Button(action: {
                selectedImageIndex = 0
                showImageViewer = true
            }) {
                RemoteImage(url: imageURLs[0], displayMode: .thumbnail(CGSize(width: 200, height: 200))) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: (maxWidth - 4) / 2, height: maxWidth)
                        .clipped()
                }
                .frame(width: (maxWidth - 4) / 2, height: maxWidth)
                .background(Color(uiColor: .systemGray6))
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(spacing: 4) {
                ForEach(Array(imageURLs[1..<3].enumerated()), id: \.offset) { index, url in
                    Button(action: {
                        selectedImageIndex = index + 1
                        showImageViewer = true
                    }) {
                        RemoteImage(url: url, displayMode: .thumbnail(CGSize(width: 200, height: 200))) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: (maxWidth - 4) / 2, height: (maxWidth - 4) / 2)
                                .clipped()
                        }
                        .frame(width: (maxWidth - 4) / 2, height: (maxWidth - 4) / 2)
                        .background(Color(uiColor: .systemGray6))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
    
    private var fourImagesView: some View {
        VStack(spacing: 4) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<2, id: \.self) { col in
                        let index = row * 2 + col
                        Button(action: {
                            selectedImageIndex = index
                            showImageViewer = true
                        }) {
                            RemoteImage(url: imageURLs[index], displayMode: .thumbnail(CGSize(width: 200, height: 200))) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: (maxWidth - 4) / 2, height: (maxWidth - 4) / 2)
                                    .clipped()
                            }
                            .frame(width: (maxWidth - 4) / 2, height: (maxWidth - 4) / 2)
                            .background(Color(uiColor: .systemGray6))
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }
    
    private var fiveOrMoreImagesView: some View {
        VStack(spacing: 4) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<2, id: \.self) { col in
                        let index = row * 2 + col
                        Button(action: {
                            selectedImageIndex = index
                            showImageViewer = true
                        }) {
                            ZStack {
                                RemoteImage(url: imageURLs[index], displayMode: .thumbnail(CGSize(width: 200, height: 200))) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: (maxWidth - 4) / 2, height: (maxWidth - 4) / 2)
                                        .clipped()
                                }
                                .frame(width: (maxWidth - 4) / 2, height: (maxWidth - 4) / 2)
                                .background(Color(uiColor: .systemGray6))
                                .overlay {
                                    if index == 3 && imageURLs.count > 4 {
                                        Color.black.opacity(0.6)
                                        Text("+\(imageURLs.count - 4)")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }
}

struct ImagePagingViewer: View {
    let imageURLs: [String]
    @Binding var selectedIndex: Int
    @Binding var isPresented: Bool
    @State private var currentPage: Int?

    init(imageURLs: [String], selectedIndex: Binding<Int>, isPresented: Binding<Bool>) {
        self.imageURLs = imageURLs
        self._selectedIndex = selectedIndex
        self._isPresented = isPresented
        self._currentPage = State(initialValue: selectedIndex.wrappedValue)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 0) {
                            ForEach(imageURLs.indices, id: \.self) { index in
                                RemoteImage(url: imageURLs[index], displayMode: .original) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                        .background(Color.black)
                                }
                                .containerRelativeFrame(.horizontal)
                                .id(index)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $currentPage)
                    .onAppear {
                        currentPage = selectedIndex
                    }
                }

                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            isPresented = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    Spacer()
                }

                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        ForEach(imageURLs.indices, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.white : Color.white.opacity(0.5))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.bottom, 20)

                    Text("\((currentPage ?? 0) + 1) / \(imageURLs.count)")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.bottom, 30)
                }
            }
        }
    }
}
