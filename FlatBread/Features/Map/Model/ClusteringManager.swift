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

    // MARK: - DBSCAN 데이터 구조
    /// DBSCAN 알고리즘에서 점의 상태를 나타내는 열거형
    enum PointStatus {
        case unvisited  // 아직 방문하지 않은 점
        case visited    // 방문한 점
        case noise      // 노이즈로 분류된 점
    }

    /// DBSCAN 알고리즘에서 각 점의 정보를 저장하는 구조체
    struct PointInfo {
        let marker: MoimMarker
        var status: PointStatus
        var clusterId: Int?
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

    /// DBSCAN에서 클러스터로 인정할 최소 점 개수 (minPts)
    /// - Parameter zoomLevel: 현재 지도 줌 레벨
    /// - Returns: 클러스터의 core point가 되기 위한 최소 이웃 개수
    private func minPointsThreshold(for zoomLevel: Double) -> Int {
        // 줌 레벨이 높을수록(확대) 더 많은 점이 필요 (덜 뭉침)
        // 줌 레벨이 낮을수록(축소) 더 적은 점으로도 클러스터 형성 (더 많이 뭉침)
        switch zoomLevel {
        case 0..<10:
            return 2  // 축소: 2개만 있어도 클러스터
        case 10..<14:
            return 2  // 중간: 2개
        case 14..<16:
            return 3  // 약간 확대: 3개
        case 16..<18:
            return 3  // 확대: 3개
        default:
            return 4  // 최대 확대: 4개 (거의 클러스터링 안 함)
        }
    }

    // MARK: - Public Methods

    /// DBSCAN 알고리즘을 사용하여 마커들을 클러스터링
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

        // DBSCAN 파라미터
        let threshold = distanceThreshold(for: zoomLevel)
        let minPts = minPointsThreshold(for: zoomLevel)

        // 1. 모든 점을 unvisited로 초기화
        var pointInfos: [String: PointInfo] = [:]
        for marker in markers {
            pointInfos[marker.id] = PointInfo(
                marker: marker,
                status: .unvisited,
                clusterId: nil
            )
        }

        // 2. 클러스터 딕셔너리와 ID 카운터
        var clusters: [Int: Cluster] = [:]
        var currentClusterId = 0

        // 3. 각 점에 대해 DBSCAN 수행
        for marker in markers {
            // 이미 방문한 점은 스킵
            guard pointInfos[marker.id]?.status == .unvisited else {
                continue
            }

            // 방문 표시
            pointInfos[marker.id]?.status = .visited

            // eps 거리 내 이웃 찾기
            let neighbors = findNeighbors(
                of: marker,
                in: markers,
                threshold: threshold,
                projection: projection
            )
            
            // minPts보다 적으면 noise로 표시
            if neighbors.count < minPts {
                pointInfos[marker.id]?.status = .noise
            } else {
                // 새 클러스터 생성 및 BFS로 확장
                currentClusterId += 1
                expandCluster(
                    startMarker: marker,
                    neighbors: neighbors,
                    clusterId: currentClusterId,
                    pointInfos: &pointInfos,
                    clusters: &clusters,
                    markers: markers,
                    threshold: threshold,
                    minPts: minPts,
                    projection: projection
                )
            }
        }

        // 4. 클러스터 배열로 변환 (noise가 아닌 점들만)
        var resultClusters: [Cluster] = Array(clusters.values)

        // 5. noise 점들은 개별 클러스터로 추가 (단일 마커 클러스터)
        var noiseCount = 0
        for (_, pointInfo) in pointInfos {
            if pointInfo.status == .noise && pointInfo.clusterId == nil {
                resultClusters.append(Cluster(markers: [pointInfo.marker]))
                noiseCount += 1
            }
        }

        for (index, cluster) in resultClusters.enumerated() {
            let markerIds = cluster.markers.map { $0.description }.joined(separator: ", ")
        }

        return resultClusters
    }

    // MARK: - Private Methods

    /// 특정 마커의 eps 거리 이내에 있는 모든 이웃 마커들을 찾음
    /// - Parameters:
    ///   - marker: 이웃을 찾을 중심 마커
    ///   - markers: 전체 마커 배열
    ///   - threshold: 이웃으로 간주할 거리 임계값 (픽셀)
    ///   - projection: 지도 좌표를 화면 좌표로 변환하는 projection
    /// - Returns: 거리 임계값 이내에 있는 마커 배열
    private func findNeighbors(
        of marker: MoimMarker,
        in markers: [MoimMarker],
        threshold: Double,
        projection: NMFProjection
    ) -> [MoimMarker] {
        let markerPoint = projection.point(from: marker.position)

        return markers.filter { other in
            // 자기 자신은 제외
            guard other.id != marker.id else { return false }

            let otherPoint = projection.point(from: other.position)
            let distance = calculateDistance(from: markerPoint, to: otherPoint)

            return distance <= threshold
        }
    }

    /// BFS를 사용하여 밀도 연결된 모든 점들을 하나의 클러스터로 확장
    /// - Parameters:
    ///   - startMarker: 클러스터의 시작 마커 (core point)
    ///   - neighbors: 시작 마커의 이웃들
    ///   - clusterId: 생성할 클러스터의 ID
    ///   - pointInfos: 모든 점들의 상태 정보
    ///   - clusters: 클러스터 딕셔너리
    ///   - markers: 전체 마커 배열
    ///   - threshold: 거리 임계값
    ///   - minPts: 최소 점 개수
    ///   - projection: 좌표 변환 projection
    private func expandCluster(
        startMarker: MoimMarker,
        neighbors: [MoimMarker],
        clusterId: Int,
        pointInfos: inout [String: PointInfo],
        clusters: inout [Int: Cluster],
        markers: [MoimMarker],
        threshold: Double,
        minPts: Int,
        projection: NMFProjection
    ) {

        // CircularQueue 초기화 - 원형 큐 사용
        var queue = CircularQueue<MoimMarker>()

        // 시작 마커의 이웃들을 큐에 추가
        for neighbor in neighbors {
            queue.enqueue(neighbor)
        }

        // 시작 마커를 클러스터에 추가
        pointInfos[startMarker.id]?.clusterId = clusterId
        clusters[clusterId] = Cluster(markers: [startMarker])

        var stepCount = 0

        // BFS로 밀도 연결된 모든 점 찾기
        while !queue.isEmpty {
            stepCount += 1
            guard let currentMarker = queue.dequeue() else { break }

            // 이미 다른 클러스터에 속한 경우 스킵
            if let info = pointInfos[currentMarker.id],
               info.clusterId != nil {
                continue
            }

            // 현재 마커를 클러스터에 추가
            pointInfos[currentMarker.id]?.clusterId = clusterId
            clusters[clusterId]?.markers.append(currentMarker)

            // 아직 방문하지 않은 점이면 이웃 확인
            if pointInfos[currentMarker.id]?.status == .unvisited {
                pointInfos[currentMarker.id]?.status = .visited

                let currentNeighbors = findNeighbors(
                    of: currentMarker,
                    in: markers,
                    threshold: threshold,
                    projection: projection
                )

                // core point라면 이웃들을 큐에 추가
                if currentNeighbors.count >= minPts {
                    for neighbor in currentNeighbors {
                        queue.enqueue(neighbor)
                    }
                }
            } else if pointInfos[currentMarker.id]?.status == .noise {
                // noise 점도 클러스터의 border point로 포함 가능
                pointInfos[currentMarker.id]?.status = .visited
            }
        }

        let finalCount = clusters[clusterId]?.count ?? 0
        let markerList = clusters[clusterId]?.markers.map { $0.description }.joined(separator: ", ") ?? ""
    }

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
