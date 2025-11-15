//
//  CreateMoimView.swift
//  FlatBread
//
//  Created by andev on 11/14/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct CreateMoimView: View {
    
    @StateObject private var vm = CreateMoimViewModel()
    
    // 바인딩용 좌표
    @State private var selectedCoord = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 타이틀
            HStack {
                Text("어떤 모임을 만들까요?")
                    .font(.system(size: 28, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
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
                                ForEach(vm.categories) { cat in
                                    ChipButton(
                                        title: cat.name,
                                        isSelected: vm.selectedCategory == cat
                                    ) {
                                        vm.selectCategory(cat)
                                    }
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
                            get: {
                                CLLocationCoordinate2D(latitude: vm.dto.latitude, longitude: vm.dto.longitude)
                            },
                            set: { vm.updateCoordinate($0) }
                        ))
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
                    
                    // MARK: - 가격 설정
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
                                    .onChange(of: vm.priceText) { oldValue, newValue in
                                        vm.commitPriceFromText()
                                    }
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
            
            // 하단 제출 버튼
            Button {
                if vm.isFree { vm.dto.price = 0 } else { vm.commitPriceFromText() }
                vm.createTapped()      // 현재는 print로 확인
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
            .disabled(!vm.canSubmit)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    CreateMoimView()
}
