//
//  VideoUploadView.swift
//  FlatBread
//
//  Created by 김민성 on 11/19/25.
//

import SwiftUI
import PhotosUI
import AVFoundation

struct VideoUploadView: View {
    
    @StateObject private var viewModel = VideoUploadViewModel()
    
    var body: some View {
        VStack(spacing: 30) {
            Text("숏폼 업로드")
                .font(.largeTitle)
                .bold()
            
            PhotosPicker(selection: $viewModel.selectedItem, matching: .videos) {
                HStack {
                    Image(systemName: "video.badge.plus")
                    Text("비디오 선택하기")
                }
                .font(.headline)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            .disabled(viewModel.isProcessing)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("상태: \(viewModel.statusMessage)")
                    .foregroundColor(viewModel.isProcessing ? .orange : .primary)
                
                if viewModel.isProcessing {
                    ProgressView()
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("원본 용량")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(viewModel.originalSizeText)
                            .bold()
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("압축 후 용량")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(viewModel.compressedSizeText)
                            .bold()
                            .foregroundColor(viewModel.isUnderLimit ? .green : .red)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            
            VStack(alignment: .leading, spacing: 16) {
                Text("카테고리 ID").font(.system(size: 16, weight: .bold))
                TextField("카테고리 ID를 입력하세요", text: $viewModel.categoryID)
                
                Text("제목").font(.system(size: 16, weight: .bold))
                TextField("제목을 입력하세요", text: $viewModel.shortVideotitleInput)
                
                Text("내용").font(.system(size: 16, weight: .bold))
                TextField("내용을 입력하세요", text: $viewModel.shortVideoContentInput)
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: viewModel.uploadVideo) {
                HStack {
                    Image(systemName: "icloud.and.arrow.up")
                    Text("서버로 업로드")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canUpload ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canUpload)
        }
        .padding()
    }
    
}

#Preview {
    VideoUploadView()
}
