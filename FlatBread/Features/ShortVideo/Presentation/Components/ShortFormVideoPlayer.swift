//
//  ShortFormVideoPlayer.swift
//  FlatBread
//
//  Created by 김민성 on 11/20/25.
//

import SwiftUI
import AVFoundation

struct ShortFormVideoPlayer: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerUIView {
        return PlayerUIView(player: player)
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
}


final class PlayerUIView: UIView {
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    init(player: AVPlayer) {
        super.init(frame: .zero)
        self.playerLayer.player = player
        self.playerLayer.videoGravity = .resizeAspectFill
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
