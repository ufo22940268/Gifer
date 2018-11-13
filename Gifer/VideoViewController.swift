//
//  EditingViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/11/10.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit
import Photos

class VideoViewController: AVPlayerViewController {
    
    override func viewDidLoad() {
    }
    
    func load(playerItem: AVPlayerItem) -> Void {
        self.player = AVPlayer(playerItem: playerItem)
    }
}

extension VideoViewController: VideoProgressDelegate {    
    func onProgressChanged(progress: CGFloat) {
        guard let player = self.player, let currentItem = player.currentItem else {
            return
        }
        
        let time = CMTime(value: CMTimeValue(Double(progress*CGFloat(currentItem.duration.value))), timescale: 600)
        player.seek(to: time)
    }
}
