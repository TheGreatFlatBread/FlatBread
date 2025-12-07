//
//  PlayerManager.swift
//  FlatBread
//
//  Created by 김민성 on 11/23/25.
//

import AVFoundation
import Combine

final class PlayerManager: ObservableObject {
    
    static let shared = PlayerManager()
    
    // AVPlayer는 3개만 생성
    private var playerPool: [AVPlayer] = []
    
    // ShortVideo별 플레이어 기록 [ShortVideo.id : AVPlayer]
    private var activePlayers: [String: AVPlayer] = [:]
    
    private init() {
        setupPool()
    }
    
    private func setupPool() {
        for _ in 0..<3 {
            let player = AVPlayer()
            player.actionAtItemEnd = .none
            playerPool.append(player)
        }
    }
    
    // MARK: - Public Methods
    
    func player(for video: ShortVideo) -> AVPlayer {
        // 이미 해당 ShortVideo에 배정된 player가 있을 경우 해당 player 반환
        if let existingPlayer = activePlayers[video.id] {
            return existingPlayer
        }
        
        let player: AVPlayer
        
        // 현재 쉬고 있는 player가 있을 경우 해당 player 사용
        if let restingPlayer = playerPool.filter({ !activePlayers.values.contains($0) }).first {
            player = restingPlayer
        } else {
            // 이미 배정되어있지도 않고, 쉬고 있는 player도 없을 경우, 가장 오랫동안 안 쓴 플레이어 사용
            player = playerPool.removeFirst()
            playerPool.append(player)
            if let oldVideoID = activePlayers.first(where: { $0.value == player })?.key {
                activePlayers.removeValue(forKey: oldVideoID)
            }
        }
        
        player.pause()
        player.replaceCurrentItem(with: nil)
        
        let newItem = AVPlayerItem(asset: video.avURLAsset)
        newItem.preferredForwardBufferDuration = 2.0
        player.replaceCurrentItem(with: newItem)
        
        activePlayers[video.id] = player
        return player
    }
    
    func pause(for video: ShortVideo) {
        if let player = activePlayers[video.id] {
            player.pause()
        }
    }
    
    func deactivatePlayer(for video: ShortVideo) {
        if let player = activePlayers[video.id] {
            player.pause()
            player.replaceCurrentItem(with: nil)
            activePlayers.removeValue(forKey: video.id)
        }
    }
}
