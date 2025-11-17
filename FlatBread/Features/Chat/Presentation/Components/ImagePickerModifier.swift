//
//  ImagePickerModifier.swift
//  FlatBread
//
//  Created by hwan on 11/15/25.
//

import SwiftUI
import PhotosUI

struct ImagePickerModifier: ViewModifier {
    @Binding var selectedImageURLs: [String]
    @Binding var showPicker: Bool

    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    func body(content: Content) -> some View {
        content
            .confirmationDialog("사진 선택", isPresented: $showPicker) {
                Button("카메라") {
                    showCamera = true
                }
                Button("보관함") {
                    showPhotoPicker = true
                }
                Button("취소", role: .cancel) {}
            }
            .sheet(isPresented: $showCamera) {
                CameraImagePicker { image in
                    handleCameraImage(image)
                }
            }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedPhotoItems,
                maxSelectionCount: 5,
                matching: .images
            )
            .onChange(of: selectedPhotoItems) { _, newItems in
                handlePhotoSelection(newItems)
            }
    }

    private func handleCameraImage(_ image: UIImage) {
        Task {
            guard let url = ImageFileManager.shared.saveImage(image) else { return }
            await MainActor.run {
                selectedImageURLs.append(url)
            }
        }
    }

    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        Task { @concurrent in
            let imageDatas = await loadImageData(from: items)
            let savedURLs = await ImageFileManager.shared.saveImagesData(imageDatas)

            await MainActor.run {
                selectedPhotoItems.removeAll()
                selectedImageURLs.append(contentsOf: savedURLs)
            }
        }
    }

    private func loadImageData(from items: [PhotosPickerItem]) async -> [Data] {
        await withTaskGroup(of: Data?.self) { group in
            for item in items {
                group.addTask {
                    try? await item.loadTransferable(type: Data.self)
                }
            }

            var results: [Data] = []
            for await data in group {
                if let data {
                    results.append(data)
                }
            }
            return results
        }
    }
}

extension View {
    func imagePicker(selectedImageURLs: Binding<[String]>, showPicker: Binding<Bool>) -> some View {
        modifier(
            ImagePickerModifier(
                selectedImageURLs: selectedImageURLs,
                showPicker: showPicker
            )
        )
    }
}
