//
//  ClusterMarker.swift
//  FlatBread
//
//  Created by 서준일 on 12/2/25.
//

import NMapsMap
import NMapsGeometry
import UIKit

/// 여러 개의 모임 마커를 하나로 묶어서 표시하는 클러스터 마커
final class ClusterMarker: NMFMarker {

    // MARK: - Properties

    /// 클러스터에 포함된 모임 마커들
    let moimMarkers: [MoimMarker]

    /// 클러스터 식별자 (포함된 마커들의 id를 조합)
    let clusterId: String

    // MARK: - Initialization

    /// ClusterMarker 초기화
    /// - Parameters:
    ///   - moimMarkers: 클러스터에 포함될 모임 마커들
    ///   - position: 클러스터의 중심 좌표
    init(moimMarkers: [MoimMarker], position: NMGLatLng) {
        self.moimMarkers = moimMarkers
        // 클러스터 ID는 포함된 마커들의 ID를 정렬해서 조합
        self.clusterId = "cluster_" + moimMarkers.map(\.id).sorted().joined(separator: "_")

        super.init()

        self.position = position
        self.iconImage = Self.createClusterIcon(count: moimMarkers.count)
        self.width = 50
        self.height = 50
        self.zIndex = 100  // 개별 마커보다 위에 표시
    }

    // MARK: - Icon Creation

    /// 클러스터 마커 아이콘 생성
    /// - Parameter count: 클러스터에 포함된 마커 개수
    /// - Returns: 숫자가 표시된 마커 이미지
    private static func createClusterIcon(count: Int) -> NMFOverlayImage {
        let size: CGFloat = 50
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))

        let image = renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: size, height: size)

            // 배경 색상 결정 (개수에 따라 다른 색상)
            let backgroundColor: UIColor
            switch count {
            case 0..<5:
                backgroundColor = UIColor.systemGreen
            case 5..<10:
                backgroundColor = UIColor.systemYellow
            case 10..<20:
                backgroundColor = UIColor.systemOrange
            default:
                backgroundColor = UIColor.systemRed
            }

            // 원형 배경 그리기
            context.cgContext.setFillColor(backgroundColor.cgColor)
            context.cgContext.fillEllipse(in: rect)

            // 테두리 그리기
            context.cgContext.setStrokeColor(UIColor.white.cgColor)
            context.cgContext.setLineWidth(3)
            context.cgContext.strokeEllipse(in: rect.insetBy(dx: 1.5, dy: 1.5))

            // 숫자 텍스트 그리기
            let countText = "\(count)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: count < 100 ? 18 : 14),
                .foregroundColor: UIColor.white
            ]

            let textSize = countText.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size - textSize.width) / 2,
                y: (size - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            countText.draw(in: textRect, withAttributes: attributes)
        }

        return NMFOverlayImage(image: image)
    }

    /// 클러스터가 포함하는 영역의 경계 계산
    /// - Returns: 포함된 모든 마커를 포함하는 경계 좌표
    func calculateBounds() -> NMGLatLngBounds {
        guard !moimMarkers.isEmpty else {
            return NMGLatLngBounds(southWest: position, northEast: position)
        }

        var minLat = moimMarkers[0].position.lat
        var maxLat = moimMarkers[0].position.lat
        var minLng = moimMarkers[0].position.lng
        var maxLng = moimMarkers[0].position.lng

        for marker in moimMarkers {
            minLat = min(minLat, marker.position.lat)
            maxLat = max(maxLat, marker.position.lat)
            minLng = min(minLng, marker.position.lng)
            maxLng = max(maxLng, marker.position.lng)
        }

        let southWest = NMGLatLng(lat: minLat, lng: minLng)
        let northEast = NMGLatLng(lat: maxLat, lng: maxLng)

        return NMGLatLngBounds(southWest: southWest, northEast: northEast)
    }
}
