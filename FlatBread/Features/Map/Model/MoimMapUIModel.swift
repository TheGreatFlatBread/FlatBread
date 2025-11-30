//
//  MoimMapUIModel.swift
//  FlatBread
//
//  Created by 김민성 on 11/6/25.
//

import NMapsGeometry
import CoreLocation
import Foundation

struct MoimMapUIModel: Identifiable, Hashable {
    
    static func == (lhs: MoimMapUIModel, rhs: MoimMapUIModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
    
    let id: String
    let name: String
    let category: String
    let currentMembers: Int
    let maxMembers: Int
    let location: NMGLatLng
    let locationName: String?
    let imageUrl: String?
    
    var asMarker: MoimMarker {
        MoimMarker(id: id, position: location)
    }
    
}


extension PostResponseDTO {
    
    var toMoimMapUIModel: MoimMapUIModel? {
        guard let id = post_id else { return nil }
        guard let category else { return nil }
        return MoimMapUIModel(
            id: id,
            name: self.title ?? "",
            category: category,
            currentMembers: self.likes2.count,
            maxMembers: 10, // 임시 값
            location: geolocation?.asNMGLatLng ?? NMGLatLng.defaultValue,
            locationName: self.value1,
            imageUrl: self.files.first
        )
    }
    
}


extension MoimMapUIModel {
    
    // 샘플 좌표 데이터
    /*
     청취사: 37.517677, 126.886442
     육삼빌딩: 37.520392, 126.939634
     경복궁: 37.579604, 126.976949
     청계천: 37.569160, 126.978530
     반포한강공원: 37.510711, 126.995731
     예술의전당: 37.479334, 127.012835
     */
    
    static func makeSample() -> [MoimMapUIModel] {
        return [
            MoimMapUIModel(
                id: "1",
                name: "새싹에서 공부하는 모임",
                category: "공부",
                currentMembers: 8,
                maxMembers: 12,
                location: .init(lat: 37.517677, lng: 126.886442),
                locationName: "테스트 지역",
                imageUrl: "https://images.unsplash.com/photo-1680022087238-eafecd5a8933?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb2ZmZWUlMjBtZWV0aW5nJTIwcGVvcGxlfGVufDF8fHx8MTc2MjM0MDE1MXww&ixlib=rb-4.1.0&q=80&w=1080",
            ),
            MoimMapUIModel(
                id: "2",
                name: "여의도 63빌딩 구경하기",
                category: "운동/액티비티",
                currentMembers: 15,
                maxMembers: 20,
                location: .init(lat: 37.520392, lng: 126.939634),
                locationName: "테스트 지역",
                imageUrl: "https://images.unsplash.com/photo-1726091983472-a7da2540c492?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxoaWtpbmclMjBncm91cCUyMG91dGRvb3J8ZW58MXx8fHwxNzYyMzQwMTUyfDA&ixlib=rb-4.1.0&q=80&w=1080",
            ),
            MoimMapUIModel(
                id: "3",
                name: "궁궐 탐방하는 모임",
                category: "독서/학습",
                currentMembers: 6,
                maxMembers: 10,
                location: .init(lat: 37.579604, lng: 126.976949),
                locationName: "테스트 지역",
                imageUrl: "https://images.unsplash.com/photo-1643316791771-ac9b7b5a2238?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxib29rJTIwY2x1YiUyMHJlYWRpbmd8ZW58MXx8fHwxNzYyMzkwMDcwfDA&ixlib=rb-4.1.0&q=80&w=1080",
            ),
            MoimMapUIModel(
                id: "4",
                name: "청계천 아침 러닝 크루 🏃",
                category: "운동/액티비티",
                currentMembers: 12,
                maxMembers: 15,
                location: .init(lat: 37.569160, lng: 126.978530),
                locationName: "테스트 지역",
                imageUrl: "https://images.unsplash.com/photo-1759167581561-3b1fbe906b52?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxydW5uaW5nJTIwZml0bmVzcyUyMGdyb3VwfGVufDF8fHx8MTc2MjQxOTY4Nnww&ixlib=rb-4.1.0&q=80&w=1080",
            ),
            MoimMapUIModel(
                id: "5",
                name: "반포한강공원에서 치맥할 사람",
                category: "카페/식사",
                currentMembers: 5,
                maxMembers: 8,
                location: .init(lat: 37.510711, lng: 126.995731),
                locationName: "테스트 지역",
                imageUrl: "https://images.unsplash.com/photo-1680022087238-eafecd5a8933?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb2ZmZWUlMjBtZWV0aW5nJTIwcGVvcGxlfGVufDF8fHx8MTc2MjM0MDE1MXww&ixlib=rb-4.1.0&q=80&w=1080",
            ),
            MoimMapUIModel(
                id: "6",
                name: "예술의전당 뮤지컬 관람 Moim",
                category: "공연/예술",
                currentMembers: 4,
                maxMembers: 8,
                location: .init(lat: 37.479334, lng: 127.012835),
                locationName: "테스트 지역",
                imageUrl: "https://images.unsplash.com/photo-1680022087238-eafecd5a8933?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb2ZmZWUlMjBtZWV0aW5nJTIwcGVvcGxlfGVufDF8fHx8MTc2MjM0MDE1MXww&ixlib=rb-4.1.0&q=80&w=1080",
            ),
        ]
    }
    
}
/*
 37.573949, 126.976582
 */
