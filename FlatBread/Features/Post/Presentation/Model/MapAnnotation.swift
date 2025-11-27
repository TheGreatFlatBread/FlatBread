//
//  MapAnnotation.swift
//  FlatBread
//
//  Created by hwan on 11/16/25.
//

import Foundation
import MapKit

struct MapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
