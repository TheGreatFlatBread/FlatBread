//
//  LocationManager.swift
//  FlatBread
//
//  Created by Claude on 11/27/25.
//

import Foundation
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject {
    @Published var currentAddress: String = "위치 정보 없음"
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkAuthorizationStatus()
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func updateLocation() {
        locationManager.requestLocation()
    }

    private func checkAuthorizationStatus() {
        authorizationStatus = locationManager.authorizationStatus

        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            updateLocation()
        case .notDetermined:
            requestLocationPermission()
        case .denied, .restricted:
            currentAddress = "위치 권한 없음"
        @unknown default:
            break
        }
    }

    private func reverseGeocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }

            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                self.currentAddress = "주소를 가져올 수 없음"
                return
            }

            if let placemark = placemarks?.first {
                // subLocality가 동 단위 주소
                if let subLocality = placemark.subLocality {
                    self.currentAddress = subLocality
                } else if let locality = placemark.locality {
                    // subLocality가 없으면 locality(시/구) 사용
                    self.currentAddress = locality
                } else {
                    self.currentAddress = "알 수 없는 위치"
                }
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            updateLocation()
        case .denied, .restricted:
            currentAddress = "위치 권한 없음"
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        reverseGeocode(location: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        currentAddress = "위치를 가져올 수 없음"
    }
}
