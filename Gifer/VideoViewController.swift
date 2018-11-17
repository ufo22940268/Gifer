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
    
    func play() {
        self.player?.play()
        addPeriodicTimeObserver()
    }
    
    func pause() {
        self.player?.pause()
        removePeriodicTimeObserver()
    }
    
    var timeObserverToken: Any?
    weak var progressDelegator: VideoProgressDelegate?
    
    func addPeriodicTimeObserver() {
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.02, preferredTimescale: timeScale)
        
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: time,
                                                           queue: .main) {
                                                            [weak self] time in
                                                            if let currentItem = self?.player?.currentItem {
                                                                let timeValue = CGFloat(time.value)/CGFloat(time.timescale)*CGFloat(currentItem.duration.timescale)
                                                                // update player transport UI
                                                                self?.progressDelegator?.onProgressChanged(progress: timeValue/CGFloat(currentItem.duration.value))
                                                            }
        }
    }
    
    func removePeriodicTimeObserver() {
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
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
