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

extension AVPlayer {
    func seek(toProgress progress: CGFloat) {
        seek(to: progress*self.currentItem!.duration)
    }
}

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
                                                            if let currentItem = self?.player?.currentItem, self!.player!.timeControlStatus == .playing {
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
    
    func seek(toProgress progress: CGFloat) {
        guard let player = self.player, let currentItem = player.currentItem else {
            return
        }
        
        let time = CMTime(value: CMTimeValue(Double(progress*CGFloat(currentItem.duration.value))), timescale: 600)
        player.seek(to: time)
    }

}

func *(progress: CGFloat, duration: CMTime) -> CMTime {
    return CMTime(value: CMTimeValue(progress*CGFloat(duration.value)), timescale: duration.timescale)
}

extension VideoViewController {
    
    func updateTrim(position: VideoTrimPosition) {
        guard let player = player, let currentItem = player.currentItem else { return }
        
        player.seek(toProgress: position.leftTrim)
        currentItem.forwardPlaybackEndTime = position.rightTrim*currentItem.duration
    }
}
