//
//  CreateMoimView.swift
//  FlatBread
//
//  Created by andev on 11/14/25.
//

import SwiftUI
import MapKit
import CoreLocation
import PhotosUI

struct CreateMoimView: View {
    
    @StateObject private var vm = CreateMoimViewModel()
    
    @State private var selectedCoord = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780) // 바인딩용 좌표
    @State private var pickerItem: PhotosPickerItem? = nil // 대표 사진 선택용
    @State private var isRegionPickerPresented = false // 지역 선택 시트 표시 여부
    @State private var showSubmitSuccessAlert = false // 업로드 성공 시 alert
    
    @FocusState private var focusedField: FocusedField? // 포커스 관리용
    
    enum FocusedField {
        case title
        case content
        case price
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("어떤 모임을 만들까요?")
                    .font(.system(size: 28, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // MARK: - 모임 대표 사진
                    VStack(alignment: .leading, spacing: 10) {
                        Text("모임 대표 사진")
                            .font(.headline)
                        
                        ZStack {
                            // 프리뷰
                            if let data = vm.selectedImageData,
                               let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 180)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            } else {
                                // 플레이스홀더
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                    .foregroundStyle(Color(.systemGray4))
                                    .frame(height: 180)
                                    .overlay {
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo.on.rectangle.angled")
                                                .font(.system(size: 26, weight: .semibold))
                                            Text("대표 이미지를 선택해 주세요")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                            }
                        }
                        
                        // 선택 버튼
                        PhotosPicker(selection: $pickerItem,
                                     matching: .images,
                                     photoLibrary: .shared()) {
                            Label("사진 선택", systemImage: "photo.fill.on.rectangle.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color(.systemGray6))
                                )
                        }
                                     .onChange(of: pickerItem) { _, newItem in
                                         guard let item = newItem else {
                                             vm.setSelectedImage(data: nil)
                                             return
                                         }
                                         Task {
                                             // Data로 로드 (HEIC/JPG 등 바이너리)
                                             if let data = try? await item.loadTransferable(type: Data.self) {
                                                 await MainActor.run { vm.setSelectedImage(data: data) }
                                             }
                                         }
                                     }
                        
                        if vm.isUploading {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("이미지 업로드 중…")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // MARK: - 모임명
                    VStack(alignment: .leading, spacing: 8) {
                        Text("모임명")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("모임명이 짧을수록 이해하기 쉬워요.", text: vm.titleBinding)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .focused($focusedField, equals: .title)
                            
                            HStack {
                                Spacer()
                                Text("\(vm.dto.title?.count ?? 0)/\(vm.titleLimit)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // MARK: - 카테고리
                    VStack(alignment: .leading, spacing: 10) {
                        Text("카테고리")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(vm.categories, id: \.self) { cat in
                                    ChipButton(
                                        title: cat.rawValue,
                                        isSelected: vm.selectedCategory == cat
                                    ) { vm.selectCategory(cat) }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // MARK: - 활동 지역
                    VStack(alignment: .leading, spacing: 10) {
                        Text("활동 지역")
                            .font(.headline)
                        MapPickerView(coordinate: Binding(
                            get: { CLLocationCoordinate2D(latitude: vm.dto.latitude, longitude: vm.dto.longitude) },
                            set: { vm.updateCoordinate($0) }
                        ))
                    // 시/군/구 선택 필드
                        VStack(alignment: .leading, spacing: 6) {
                            Text("시/군/구")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Button {
                                isRegionPickerPresented = true
                            } label: {
                                HStack {
                                    Text(vm.selectedRegionName ?? "시/군/구를 선택해 주세요.")
                                        .foregroundStyle(vm.selectedRegionName == nil ? .secondary : .primary)
                                        .lineLimit(1)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 16)
                    
                    // MARK: - 모임 소개
                    VStack(alignment: .leading, spacing: 8) {
                        Text("모임 소개")
                            .font(.headline)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: vm.contentBinding)
                                .frame(minHeight: 160, maxHeight: .infinity)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .focused($focusedField, equals: .content)
                            
                            if (vm.dto.content ?? "").isEmpty {
                                Text("활동 중심으로 모임을 소개해주세요. 소개를 잘 작성한 모임은 2배 많은 이웃이 가입해요.")
                                    .foregroundStyle(.secondary)
                                    .font(.body)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .allowsHitTesting(false)
                            }
                        }
                        
                        HStack {
                            Spacer()
                            Text("\(vm.dto.content?.count ?? 0)/\(vm.contentLimit)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // MARK: - 입장료 설정
                    VStack(alignment: .leading, spacing: 10) {
                        Text("입장료 설정")
                            .font(.headline)
                        
                        Toggle("무료", isOn: Binding(
                            get: { vm.isFree },
                            set: { vm.toggleFree($0) }
                        ))
                        .toggleStyle(.switch)
                        
                        if !vm.isFree {
                            HStack(spacing: 8) {
                                Text("₩")
                                    .font(.system(size: 18, weight: .semibold))
                                TextField("금액 입력 (원)", text: $vm.priceText)
                                    .keyboardType(.numberPad)
                                    .onChange(of: vm.priceText) { _, _ in
                                        vm.commitPriceFromText()
                                    }
                                    .focused($focusedField, equals: .price)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 24)
                }
                .padding(.vertical, 12)
            }
            
            // 업로드 진행 중 표시
            if vm.isUploading {
                GearLoadingView(progress: vm.uploadProgress)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
            }
            
            // 하단 제출 버튼
            Button {
                Task {
                    let success = await vm.submit() // 업로드 → URL 반영 → 생성
                    if success {
                        showSubmitSuccessAlert = true
                    }
                }
            } label: {
                Text("모임 만들기")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(vm.canSubmit ? Color.black : Color(.systemGray5))
                    .foregroundStyle(vm.canSubmit ? .white : .secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .disabled(!vm.canSubmit || vm.isUploading)
            .background(Color(.systemBackground))
        }
        .onTapGesture {
            focusedField = nil
        }
        .background(Color(.systemBackground))
        .alert(
            "모임 생성 실패",
            isPresented: Binding(
                get: { vm.uploadErrorMessage != nil },
                set: { newValue in if !newValue { vm.uploadErrorMessage = nil } }
            )
        ) {
            Button("확인", role: .cancel) {
                vm.uploadErrorMessage = nil
            }
        } message: {
            Text(vm.uploadErrorMessage ?? "모임 생성에 실패했습니다. 다시 시도해 주세요.")
        }

        // 성공 Alert
        .alert("모임 생성 완료", isPresented: $showSubmitSuccessAlert) {
            Button("확인", role: .cancel) {
                showSubmitSuccessAlert = false
                // 필요하면 여기서 화면 dismiss 처리 등
            }
        } message: {
            Text("모임이 성공적으로 생성되었습니다.")
        }
        // 지역 검색 시트
        .sheet(isPresented: $isRegionPickerPresented) {
            RegionSearchView(
                allRegions: vm.allRegions,
                selected: vm.selectedRegionName,
                onSelect: { region in
                    vm.selectRegionName(region)
                    isRegionPickerPresented = false
                }
            )
        }
    }
}

#Preview {
    CreateMoimView()
}
