//
//  MoimMarker.swift
//  FlatBread
//
//  Created by 김민성 on 11/8/25.
//

import NMapsMap
import NMapsGeometry

final class MoimMarker: NMFMarker {
    
    let id: String
    
    init(id: String, position: NMGLatLng) {
        self.id = id
        super.init()
        self.position = position
        self.iconImage = NMF_MARKER_IMAGE_YELLOW
    }
    
}
