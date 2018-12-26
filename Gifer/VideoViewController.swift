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

class VideoPreviewView: UIImageView {

    init() {
        super.init(frame: CGRect.zero)
        contentMode = .scaleAspectFit
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

protocol VideoViewControllerDelegate: class {
    
    func onProgressChanged(progress: CGFloat)
    
    func onBuffering(_ inBuffering: Bool)
    
    func updatePlaybackStatus(_ status: AVPlayer.TimeControlStatus)
}

class VideoViewController: AVPlayerViewController {
    
    var previewView: VideoPreviewView!
    
    override func viewDidLoad() {
        if let contentOverlayView = contentOverlayView {
            previewView = VideoPreviewView()
            previewView.translatesAutoresizingMaskIntoConstraints = false
            contentOverlayView.addSubview(previewView);
            NSLayoutConstraint.activate([
                previewView.leadingAnchor.constraint(equalTo: contentOverlayView.leadingAnchor),
                previewView.trailingAnchor.constraint(equalTo: contentOverlayView.trailingAnchor),
                previewView.topAnchor.constraint(equalTo: contentOverlayView.topAnchor),
                previewView.bottomAnchor.constraint(equalTo: contentOverlayView.bottomAnchor)
                ])
            previewView.backgroundColor = UIColor.black 
        }
    }
    
    func load(playerItem: AVPlayerItem) -> Void {
        self.player = AVPlayer(playerItem: playerItem)
        addPeriodicTimeObserver()
    }
    
    func setPreviewImage(_ image: UIImage) {
        previewView.image = image
    }
    
    func play() {
        self.player?.play()
    }
    
    func pause() {
        self.player?.pause()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        removePeriodicTimeObserver()
    }
    
    var timeObserverToken: Any?
    var boundaryObserverToken: Any?
    let observeInterval = CMTime(seconds: 0.02, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    weak var videoViewControllerDelegate: VideoViewControllerDelegate?
    
    func addPeriodicTimeObserver() {
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: observeInterval,
                                                           queue: .main) {
                                                            [weak self] time in
                                                            self?.observePlaybackStatus(currentTime: time)
        }
        
        boundaryObserverToken = player?.addBoundaryTimeObserver(forTimes: [NSValue(time: CMTime(seconds: 0.0001, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))], queue: DispatchQueue.main, using: {
            self.previewView.isHidden = true
        })
    }
    
    func observePlaybackStatus(currentTime: CMTime) {
        guard let currentItem = self.player?.currentItem else {return}
        self.videoViewControllerDelegate?.updatePlaybackStatus(self.player!.timeControlStatus)
        
        if self.player!.timeControlStatus == .playing {
            let progress = CGFloat(currentTime.value)/CGFloat(currentTime.timescale)/(CGFloat(currentItem.duration.value)/CGFloat(currentItem.duration.timescale))
            self.videoViewControllerDelegate?.onProgressChanged(progress:
                progress)
        }
        
        if currentItem.status == .readyToPlay {
            showLoading(!currentItem.isPlaybackLikelyToKeepUp)
        }
    }
    
    func showLoading(_ show: Bool) {
        self.videoViewControllerDelegate?.onBuffering(show)
    }
    
    func removePeriodicTimeObserver() {
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        
        if let observer = boundaryObserverToken {
            player?.removeTimeObserver(observer)
            self.boundaryObserverToken = nil
        }
    }
    
    func seek(toProgress progress: CGFloat) {
        guard let player = self.player, let currentItem = player.currentItem else {
            return
        }
        
        let newTimeValue: CMTimeValue = CMTimeValue(Double(progress*CGFloat(currentItem.duration.value)) + 0.5)
        let time = CMTime(value: newTimeValue, timescale: 600)
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
