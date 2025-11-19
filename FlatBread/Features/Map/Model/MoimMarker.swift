//
//  MoimMarker.swift
//  FlatBread
//
//  Created by 김민성 on 11/8/25.
//

import NMapsMap
import NMapsGeometry

final class MoimMarker: NMFMarker {
    
    // 마커 메모리 누수 확인용
    #if DEBUG
    static var markerCount: Int = 0
    #endif
    
    let id: String
    
    init(id: String, position: NMGLatLng) {
        self.id = id
        super.init()
        self.position = position
        self.iconImage = .init(image: .mapMarker.withTintColor(.juhwang))
        
        #if DEBUG
        Self.markerCount += 1
        #endif
    }
    
    #if DEBUG
    deinit {
        Self.markerCount -= 1
    }
    #endif
    
}
