//
//  ClusteringManager.swift
//  FlatBread
//
//  Created by 서준일 on 12/2/25.
//

import Foundation
import NMapsMap
import NMapsGeometry

/// 마커 클러스터링을 담당하는 매니저
final class ClusteringManager {

    // MARK: - Cluster 데이터 구조
    /// 하나의 클러스터를 나타내는 구조체
    struct Cluster {
        var markers: [MoimMarker]

        /// 클러스터의 중심 좌표 (포함된 마커들의 평균 위치)
        var centerPosition: NMGLatLng {
            guard !markers.isEmpty else { return .defaultValue }

            let totalLat = markers.reduce(0.0) { $0 + $1.position.lat }
            let totalLng = markers.reduce(0.0) { $0 + $1.position.lng }

            return NMGLatLng(
                lat: totalLat / Double(markers.count),
                lng: totalLng / Double(markers.count)
            )
        }

        /// 클러스터에 포함된 마커 개수
        var count: Int {
            markers.count
        }
    }

    // MARK: - Properties

    /// 줌 레벨에 따른 픽셀 거리 임계값 반환
    /// - Parameter zoomLevel: 현재 지도 줌 레벨
    /// - Returns: 클러스터링 판단을 위한 픽셀 거리 임계값
    private func distanceThreshold(for zoomLevel: Double) -> Double {
        // 줌 레벨이 높을수록(확대) 임계값을 줄여서 덜 뭉침
        // 줌 레벨이 낮을수록(축소) 임계값을 늘려서 더 많이 뭉침
        switch zoomLevel {
        case 0..<8:
            return 100.0  // 매우 축소: 넓은 범위 클러스터링
        case 8..<10:
            return 80.0
        case 10..<12:
            return 60.0
        case 12..<14:
            return 45.0
        case 14..<16:
            return 30.0
        case 16..<17:
            return 15.0   // 거의 확대: 매우 좁은 범위만 클러스터링
        case 17..<18:
            return 5.0    // 매우 확대: 거의 같은 위치만 클러스터링
        default:
            return 0.0    // 최대 확대: 클러스터링 비활성화
        }
    }

    // MARK: - Public Methods

    /// 마커들을 클러스터링하여 결과 반환
    /// - Parameters:
    ///   - markers: 클러스터링할 마커 배열
    ///   - zoomLevel: 현재 지도 줌 레벨
    ///   - projection: 지도 좌표를 화면 좌표로 변환하는 projection
    /// - Returns: 클러스터 배열
    func cluster(
        markers: [MoimMarker],
        zoomLevel: Double,
        projection: NMFProjection
    ) -> [Cluster] {
        guard !markers.isEmpty else { return [] }

        let threshold = distanceThreshold(for: zoomLevel)
        var clusters: [Cluster] = []
        var processedMarkers = Set<String>()

        // 1단계: 같은 위치(5px 이내)의 마커들을 먼저 클러스터링
        // 이들은 줌 레벨과 관계없이 항상 클러스터로 표시
        let sameLocationThreshold: Double = 5.0

        for marker in markers {
            if processedMarkers.contains(marker.id) {
                continue
            }

            let markerPoint = projection.point(from: marker.position)
            var newCluster = Cluster(markers: [marker])
            processedMarkers.insert(marker.id)

            // 같은 위치에 있는 마커들 찾기
            for otherMarker in markers {
                if processedMarkers.contains(otherMarker.id) {
                    continue
                }

                let otherPoint = projection.point(from: otherMarker.position)
                let distance = calculateDistance(from: markerPoint, to: otherPoint)

                // 같은 위치로 간주되는 거리 (5px 이내)
                if distance <= sameLocationThreshold {
                    newCluster.markers.append(otherMarker)
                    processedMarkers.insert(otherMarker.id)
                }
            }

            // 같은 위치에 2개 이상의 마커가 있으면 항상 클러스터로 추가
            if newCluster.count >= 2 {
                clusters.append(newCluster)
            } else {
                // 1개만 있는 경우는 다시 처리 대기열에 추가
                processedMarkers.remove(marker.id)
            }
        }

        // 2단계: 남은 마커들에 대해 줌 레벨 기반 클러스터링 수행
        let remainingMarkers = markers.filter { !processedMarkers.contains($0.id) }

        for marker in remainingMarkers {
            if processedMarkers.contains(marker.id) {
                continue
            }

            let markerPoint = projection.point(from: marker.position)
            var newCluster = Cluster(markers: [marker])
            processedMarkers.insert(marker.id)

            // 줌 레벨 기반 임계값으로 클러스터링
            for otherMarker in remainingMarkers {
                if processedMarkers.contains(otherMarker.id) {
                    continue
                }

                let otherPoint = projection.point(from: otherMarker.position)
                let distance = calculateDistance(from: markerPoint, to: otherPoint)

                if distance <= threshold {
                    newCluster.markers.append(otherMarker)
                    processedMarkers.insert(otherMarker.id)
                }
            }

            clusters.append(newCluster)
        }

        return clusters
    }

    // MARK: - Private Methods

    /// 두 화면 좌표 간의 거리 계산
    /// - Parameters:
    ///   - point1: 첫 번째 좌표
    ///   - point2: 두 번째 좌표
    /// - Returns: 픽셀 단위 거리
    private func calculateDistance(from point1: CGPoint, to point2: CGPoint) -> Double {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(dx * dx + dy * dy)
    }
}
