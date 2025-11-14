//
//  MoimInMainMap.swift
//  FlatBread
//
//  Created by 김민성 on 11/6/25.
//

import NMapsGeometry
import CoreLocation
import Foundation

struct MoimInMainMap: Identifiable, Hashable {
    
    static func == (lhs: MoimInMainMap, rhs: MoimInMainMap) -> Bool {
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
    let location: CLLocationCoordinate2D
    let imageUrl: String
    
    var asMarker: MoimMarker {
        MoimMarker(id: id, position: NMGLatLng(from: location))
    }
    
}


extension MoimInMainMap {
    
    // 샘플 좌표 데이터
    /*
     청취사: 37.517677, 126.886442
     육삼빌딩: 37.520392, 126.939634
     경복궁: 37.579604, 126.976949
     청계천: 37.569160, 126.978530
     반포한강공원: 37.510711, 126.995731
     예술의전당: 37.479334, 127.012835
     */
    
    static func makeSample() -> [MoimInMainMap] {
        return [
            MoimInMainMap(
                id: "1",
                name: "새싹에서 공부하는 모임",
                category: "공부",
                currentMembers: 8,
                maxMembers: 12,
                location: .init(latitude: 37.517677, longitude: 126.886442),
                imageUrl: "https://images.unsplash.com/photo-1680022087238-eafecd5a8933?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb2ZmZWUlMjBtZWV0aW5nJTIwcGVvcGxlfGVufDF8fHx8MTc2MjM0MDE1MXww&ixlib=rb-4.1.0&q=80&w=1080",
            ),
            MoimInMainMap(
                id: "2",
                name: "여의도 63빌딩 구경하기",
                category: "운동/액티비티",
                currentMembers: 15,
                maxMembers: 20,
                location: .init(latitude: 37.520392, longitude: 126.939634),
                imageUrl: "https://images.unsplash.com/photo-1726091983472-a7da2540c492?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxoaWtpbmclMjBncm91cCUyMG91dGRvb3J8ZW58MXx8fHwxNzYyMzQwMTUyfDA&ixlib=rb-4.1.0&q=80&w=1080",
            ),
            MoimInMainMap(
                id: "3",
                name: "궁궐 탐방하는 모임",
                category: "독서/학습",
                currentMembers: 6,
                maxMembers: 10,
                location: .init(latitude: 37.579604, longitude: 126.976949),
                imageUrl: "https://images.unsplash.com/photo-1643316791771-ac9b7b5a2238?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxib29rJTIwY2x1YiUyMHJlYWRpbmd8ZW58MXx8fHwxNzYyMzkwMDcwfDA&ixlib=rb-4.1.0&q=80&w=1080",
            ),
            MoimInMainMap(
                id: "4",
                name: "청계천 아침 러닝 크루 🏃",
                category: "운동/액티비티",
                currentMembers: 12,
                maxMembers: 15,
                location: .init(latitude: 37.569160, longitude: 126.978530),
                imageUrl: "https://images.unsplash.com/photo-1759167581561-3b1fbe906b52?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxydW5uaW5nJTIwZml0bmVzcyUyMGdyb3VwfGVufDF8fHx8MTc2MjQxOTY4Nnww&ixlib=rb-4.1.0&q=80&w=1080",
            ),
            MoimInMainMap(
                id: "5",
                name: "반포한강공원에서 치맥할 사람",
                category: "카페/식사",
                currentMembers: 5,
                maxMembers: 8,
                location: .init(latitude: 37.510711, longitude: 126.995731),
                imageUrl: "https://images.unsplash.com/photo-1680022087238-eafecd5a8933?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb2ZmZWUlMjBtZWV0aW5nJTIwcGVvcGxlfGVufDF8fHx8MTc2MjM0MDE1MXww&ixlib=rb-4.1.0&q=80&w=1080",
            ),
            MoimInMainMap(
                id: "6",
                name: "예술의전당 뮤지컬 관람 Moim",
                category: "공연/예술",
                currentMembers: 4,
                maxMembers: 8,
                location: .init(latitude: 37.479334, longitude: 127.012835),
                imageUrl: "https://images.unsplash.com/photo-1680022087238-eafecd5a8933?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb2ZmZWUlMjBtZWV0aW5nJTIwcGVvcGxlfGVufDF8fHx8MTc2MjM0MDE1MXww&ixlib=rb-4.1.0&q=80&w=1080",
            ),
        ]
    }
    
}
