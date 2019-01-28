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

typealias progress = CMTime

func / (_ l: CMTime, _ r: CMTime) -> Double {
    return Double(l.value)/Double(r.value)
}

func * (_ l: CMTime, _ r: Double) -> CMTime {
    return CMTime(value: CMTimeValue(Double(l.value)*r), timescale: l.timescale)
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
    
    func onProgressChanged(progress: CMTime)
    
    func onBuffering(_ inBuffering: Bool)
    
    func updatePlaybackStatus(_ status: AVPlayer.TimeControlStatus)
    
    func onVideoReady(controller: AVPlayerViewController)
}

class VideoViewController: AVPlayerViewController {
    
    var previewView: VideoPreviewView!
    var trimPosition: VideoTrimPosition!
    var currentRate: Float = 1
    var dismissed: Bool = false
    var videoInited: Bool = false
    
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
        guard !dismissed else {
            return
        }
        self.player = AVPlayer(playerItem: playerItem)
        trimPosition = VideoTrimPosition(leftTrim: CMTime.zero, rightTrim: playerItem.duration)
        self.player?.isMuted = true
        addObservers()
        play()
    }
    
    func setPreviewImage(_ image: UIImage) {
        previewView.image = image
    }
    
    func setRate(_ rate: Float) {
        self.player?.rate = rate
        self.currentRate = rate
    }
    
    func play() {
        self.player?.play()
    }
    
    func pause() {
        self.player?.pause()
    }
    
    func stop() {
        self.player?.pause()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        removeObservers()
    }
    
    var timeObserverToken: Any?
    var boundaryObserverToken: Any?
    let observeInterval = CMTime(seconds: 0.01, preferredTimescale: 600)
    weak var videoViewControllerDelegate: VideoViewControllerDelegate?
    weak var loopObserver: NSObjectProtocol?
    
    func addObservers() {
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: observeInterval,
                                                           queue: .main) {
                                                            [weak self] time in
                                                            self?.observePlaybackStatus(currentTime: time)
        }
        
        boundaryObserverToken = player?.addBoundaryTimeObserver(forTimes: [NSValue(time: CMTime(seconds: 0.1, preferredTimescale: 600))], queue: DispatchQueue.main, using: { [weak self] in
            guard let self = self else { return }
        })
        
        loopObserver = NotificationCenter.default.addObserver(forName: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { (notif) in
            guard let player = self.player else { return }
            player.seek(to: self.trimPosition.leftTrim)
            player.playImmediately(atRate: self.currentRate)
        }
    }
    
    func observePlaybackStatus(currentTime: CMTime) {
        guard let currentItem = self.player?.currentItem else {return}
        let currentTime = currentTime.convertScale(600, method: .default)
        
        if videoInited == false && currentItem.status == .readyToPlay {
            setupWhenVideoIsReadyToPlay()
            videoInited = true
        }
        
        if self.player!.timeControlStatus == .playing {
            self.videoViewControllerDelegate?.onProgressChanged(progress:
                currentTime)
        }
        
        if currentItem.status == .readyToPlay {
            showLoading(!currentItem.isPlaybackLikelyToKeepUp)
        }
    }
    
    func setupWhenVideoIsReadyToPlay() {
        self.videoViewControllerDelegate?.onVideoReady(controller: self)
    }
    
    func showLoading(_ show: Bool) {
        self.videoViewControllerDelegate?.onBuffering(show)
    }
    
    func removeObservers() {
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        
        if let observer = boundaryObserverToken {
            player?.removeTimeObserver(observer)
            self.boundaryObserverToken = nil
        }
        
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func seek(toProgress progress: CMTime) {
        guard let player = self.player else {
            return
        }
        
        player.seek(to: progress)
    }

}

func *(progress: CGFloat, duration: CMTime) -> CMTime {
    return CMTime(value: CMTimeValue(progress*CGFloat(duration.value)), timescale: duration.timescale)
}

extension VideoViewController {
    
    func updateTrim(position: VideoTrimPosition, state: VideoTrimState) {
        guard let player = player, let currentItem = player.currentItem else { return }
        
        trimPosition = position
        currentItem.forwardPlaybackEndTime = position.rightTrim
        if state == .finished {
            player.seek(to: position.leftTrim)
        }
    }
}
