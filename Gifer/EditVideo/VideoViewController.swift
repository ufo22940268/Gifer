//
//  EditingViewController.swift//  Gifer
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
        isUserInteractionEnabled = false
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
    var previewImage: UIImage?
    var filter: YPFilter?
    var playDirection: PlayDirection = .forward {
        didSet {
            updateEndtime()
        }
    }
    
    private func updateEndtime() {
        guard let currentItem = player?.currentItem else { return }
        switch playDirection {
        case .forward:
            currentItem.forwardPlaybackEndTime = trimPosition.rightTrim
            currentItem.reversePlaybackEndTime = .invalid
        case .backward:
            currentItem.forwardPlaybackEndTime = .invalid
            currentItem.reversePlaybackEndTime = trimPosition.leftTrim
        }
    }
    
    var currentItem: AVPlayerItem? {
        return self.player?.currentItem
    }
    
    func load(playerItem: AVPlayerItem) -> Void {
        guard !dismissed else {
            return
        }
        self.player = AVPlayer(playerItem: playerItem)
        trimPosition = VideoTrimPosition(leftTrim: CMTime.zero, rightTrim: playerItem.duration)
        self.player?.isMuted = true
        videoGravity = .resize
        
        player!.currentItem!.videoComposition = buildVideoComposition(filter: AllFilters.first!)

        addObservers()
    }
    
    func setFilter(_ filter: YPFilter) {
        self.filter = filter
        self.player?.currentItem?.videoComposition = buildVideoComposition(filter: filter)
    }
    
    func buildVideoComposition(filter: YPFilter) -> AVVideoComposition? {
        guard let asset = player?.currentItem?.asset else {
            return nil
        }

        let composition = AVMutableVideoComposition(asset: asset) { (request) in
            var image = request.sourceImage
            image = filter.applyFilter(image: image)
            request.finish(with: image, context: nil)
        }
        return composition
    }
    
    func setRate(_ rate: Float) {
        self.player?.rate = rate
        self.currentRate = rate
    }
    
    func play() {
        self.player?.rate = (playDirection == .forward ? 1 : -1)*currentRate
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
        let observeInterval = CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: observeInterval,
                                                           queue: .main) {
                                                            [weak self] time in                                                                                             self?.observePlaybackStatus()
        }

        loopObserver = NotificationCenter.default.addObserver(forName: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { (notif) in
            guard let player = self.player, let currentItem = player.currentItem else { return }
            let meetEnds: Bool
            switch self.playDirection {
            case .forward:
                meetEnds = currentItem.currentTime() == currentItem.forwardPlaybackEndTime
            case .backward:
                meetEnds = currentItem.currentTime() == currentItem.reversePlaybackEndTime
            }
            if meetEnds {
                player.seek(to: self.playDirection == .forward ? self.trimPosition.leftTrim : self.trimPosition.rightTrim, toleranceBefore: .zero, toleranceAfter: .zero)
                self.play()
            }
        }
        
        self.player?.currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let currentItem = player?.currentItem else { return }
        if keyPath == #keyPath(AVPlayerItem.status) {
            if videoInited == false && currentItem.status == .readyToPlay {
                setupWhenVideoIsReadyToPlay()
                videoInited = true
            }
        }
    }
    
    func observePlaybackStatus() {
        guard let currentItem = self.player?.currentItem else { return }
        let currentTime = currentItem.currentTime()
        showLoading(currentItem.isPlaybackBufferEmpty)
        if self.player!.timeControlStatus == .playing {
            if currentItem.isPlaybackLikelyToKeepUp {
                previewView.isHidden = true
                self.videoViewControllerDelegate?.onProgressChanged(progress:
                    currentTime)
            }
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
            self.player?.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: nil)
        }
        
    }
    
    func seek(toProgress progress: CMTime) {
        guard let player = self.player else {
            return
        }

//        showLoading(true)
        let tolerance = CMTime.zero
        player.seek(to: progress, toleranceBefore: tolerance, toleranceAfter: tolerance, completionHandler: {success in
        })
    }

}

func *(progress: CGFloat, duration: CMTime) -> CMTime {
    return CMTime(value: CMTimeValue(progress*CGFloat(duration.value)), timescale: duration.timescale)
}

extension VideoViewController {
    
    func updateTrim(position: VideoTrimPosition, state: VideoTrimState, sliderPosition: CMTime? = nil) {
        guard let player = player, let currentItem = player.currentItem else { return }
        
        trimPosition = position
        
        switch state {
        case .finished(let forceReset):
            var reset:Bool
            if !forceReset {
                reset = currentItem.currentTime() < position.leftTrim || currentItem.currentTime() > position.rightTrim
                if reset == false, let sliderPosition = sliderPosition {
                    seek(toProgress: sliderPosition)
                }
            } else {
                reset = true
            }
            
            if reset {
                seek(toProgress: position.leftTrim)
            }
            updateEndtime()
            play()
        case .started:
            pause()
        case .moving(let seekToSlider):
            if seekToSlider {
                player.seek(to: sliderPosition!, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            }
        default:
            updateEndtime()
        }
    }
}
