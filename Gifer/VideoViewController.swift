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
    weak var videoViewControllerDelegate: VideoViewControllerDelegate?
    weak var loopObserver: NSObjectProtocol?
    
    func addObservers() {
        guard let currentItem = player?.currentItem else { return  }
        let observeInterval = CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: observeInterval,
                                                           queue: .main) {
                                                            [weak self] time in                                                                                             self?.observePlaybackStatus(currentTime: time)
        }

        loopObserver = NotificationCenter.default.addObserver(forName: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { (notif) in
            guard let player = self.player else { return }
            player.seek(to: self.trimPosition.leftTrim)
            player.playImmediately(atRate: self.currentRate)
        }
        
        currentItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let currentItem = player?.currentItem else { return  }
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            
            // Get the status change from the change dictionary
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            if videoInited == false && currentItem.status == .readyToPlay {
                setupWhenVideoIsReadyToPlay()
                videoInited = true
            }
        }
    }
    
    func observePlaybackStatus(currentTime: CMTime) {
        guard let currentItem = self.player?.currentItem else {return}
        let currentTime = currentTime.convertScale(600, method: .default)
        
        showLoading(!currentItem.isPlaybackLikelyToKeepUp)
        if self.player!.timeControlStatus == .playing {
            self.videoViewControllerDelegate?.onProgressChanged(progress:
                currentTime)
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
        
        switch state {
        case .finished(let forceReset):
            currentItem.forwardPlaybackEndTime = position.rightTrim

            var reset:Bool
            if !forceReset {
                reset = currentItem.currentTime() < position.leftTrim || currentItem.currentTime() > position.rightTrim
            } else {
                reset = true
            }
            
            if reset {
                player.seek(to: position.leftTrim)
            }
            play()
        case .started:
            pause()
        default:
            break
        }
    }
}
