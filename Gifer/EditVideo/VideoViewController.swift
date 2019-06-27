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
}

class VideoViewController: UIViewController {
    
    var previewView: VideoPreviewView!
    var trimPosition: VideoTrimPosition!
    var currentRate: Float = 1
    var dismissed: Bool = false
    var videoInited: Bool = false
    var previewImage: UIImage?
    var filter: YPFilter?
    
    @IBOutlet var imagePlayerView: ImagePlayerView!
    var player: AVPlayer!
    var videoBounds: CGRect {
        return CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
    }
    
    var playDirection: PlayDirection = .forward {
        didSet {
        }
    }
    
    func load(playerItem: ImagePlayerItem) -> Void {
        trimPosition = VideoTrimPosition(leftTrim: .zero, rightTrim: playerItem.duration)
        imagePlayerView.load(playerItem: playerItem)
        imagePlayerView.play()
//        guard !dismissed else {
//            return
//        }
//        self.player = AVPlayer(playerItem: playerItem)
//        trimPosition = VideoTrimPosition(leftTrim: CMTime.zero, rightTrim: playerItem.duration)
//        self.player?.isMuted = true
//        videoGravity = .resize
//
//        player!.currentItem!.videoComposition = buildVideoComposition(filter: AllFilters.first!)
//
//        addObservers()
//
    }
    
    func setFilter(_ filter: YPFilter) {
//        self.filter = filter
//        self.player?.currentItem?.videoComposition = buildVideoComposition(filter: filter)
    }
    
//    func buildVideoComposition(filter: YPFilter) -> AVVideoComposition? {
//        guard let asset = player?.currentItem?.asset else {
//            return nil
//        }
//
//        let composition = AVMutableVideoComposition(asset: asset) { (request) in
//            var image = request.sourceImage
//            image = filter.applyFilter(image: image)
//            request.finish(with: image, context: nil)
//        }
//        return composition
//    }
    
    func setRate(_ rate: Float) {
        self.player?.rate = rate
        self.currentRate = rate
    }
    
    func play() {
//        self.player?.rate = (playDirection == .forward ? 1 : -1)*currentRate
    }
    
    func pause() {
//        self.player?.pause()
    }
    
    func stop() {
//        self.player?.pause()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
//        removeObservers()
    }
    
    weak var videoViewControllerDelegate: VideoViewControllerDelegate?
    weak var loopObserver: NSObjectProtocol?
    
    func addObservers() {
//        let observeInterval = CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
//        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: observeInterval,
//                                                           queue: .main) {
//                                                            [weak self] time in                                                                                             self?.observePlaybackStatus()
//        }
//
//        loopObserver = NotificationCenter.default.addObserver(forName: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { (notif) in
//            guard let player = self.player, let currentItem = player.currentItem else { return }
//            let meetEnds: Bool
//            switch self.playDirection {
//            case .forward:
//                meetEnds = currentItem.currentTime() == currentItem.forwardPlaybackEndTime
//            case .backward:
//                meetEnds = currentItem.currentTime() == currentItem.reversePlaybackEndTime
//            }
//            if meetEnds {
//                player.seek(to: self.playDirection == .forward ? self.trimPosition.leftTrim : self.trimPosition.rightTrim, toleranceBefore: .zero, toleranceAfter: .zero)
//                self.play()
//            }
//        }
//
//        self.player?.currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: nil)
    }
    
    
//    func observePlaybackStatus() {
//        guard let currentItem = self.player?.currentItem else { return }
//        let currentTime = currentItem.currentTime()
//        showLoading(currentItem.isPlaybackBufferEmpty)
//        if self.player!.timeControlStatus == .playing {
//            if currentItem.isPlaybackLikelyToKeepUp {
//                previewView.isHidden = true
//                self.videoViewControllerDelegate?.onProgressChanged(progress:
//                    currentTime)
//            }
//        }
//    }
    
    func seek(toProgress progress: CMTime, andPlay play: Bool = true) {
//        guard let player = self.player, currentItem?.status == .readyToPlay else {
//            return
//        }
//
//        if play {
//            currentItem?.cancelPendingSeeks()
//            isChasing = false
//        }
//
//        guard !isChasing else { return }
//        chaseTime = progress
//        let chaseTimeInProgress = chaseTime!
//        isChasing = true
//        player.seek(to: chaseTimeInProgress, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: {success in
//            self.isChasing = false
//            if let chaseTime = self.chaseTime, chaseTime != chaseTimeInProgress {
//                self.seek(toProgress: chaseTime, andPlay: false)
//            }
//
//            if play {
//                player.play()
//                self.updateEndtime()
//            }
//        })
    }

}

func *(progress: CGFloat, duration: CMTime) -> CMTime {
    return CMTime(value: CMTimeValue(progress*CGFloat(duration.value)), timescale: duration.timescale)
}

extension VideoViewController {
    
    func updateTrim(position: VideoTrimPosition, state: VideoTrimState, side: TrimController.Side) {
        var toProgress: CMTime!
        if side == .left {
            toProgress = position.leftTrim
        } else {
            toProgress = position.rightTrim
        }
        imagePlayerView.seek(to: toProgress)
        
        switch state {
        case .started:
            imagePlayerView.paused = true
        case .finished(_):
            imagePlayerView.paused = false
        default:
            break
        }

//        guard let player = player, let _ = player.currentItem else { return }
//
//        trimPosition = position
//
//        var toProgress: CMTime!
//        if side == .left {
//            toProgress = position.leftTrim
//        } else {
//            toProgress = position.rightTrim
//        }
//        if case .finished(_) = state {
//            seek(toProgress: toProgress, andPlay: true)
//        } else {
//            if case .started = state {
//                currentItem?.cancelPendingSeeks()
//                pause()
//            }
//
//            if case .initial = state {
//                updateEndtime()
//            }
//
//            seek(toProgress: toProgress, andPlay: false)
//        }
    }
}
