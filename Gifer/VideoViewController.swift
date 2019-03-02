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
    
    func getVideoComposition(videoAsset: AVAsset) -> AVVideoComposition {
        let ciContext = CIContext(eaglContext: EAGLContext(api: EAGLRenderingAPI.openGLES3)!)
        let composition = AVVideoComposition(asset: videoAsset) { (request) in
            
            let outputImage = request.sourceImage.clampedToExtent().applyingFilter("CIGaussianBlur").cropped(to: request.sourceImage.extent)
            request.finish(with: outputImage, context: ciContext)
            
        }
        return composition
    }
    
    func load(playerItem: AVPlayerItem) -> Void {
        guard !dismissed else {
            return
        }
        self.player = AVPlayer(playerItem: playerItem)
        trimPosition = VideoTrimPosition(leftTrim: CMTime.zero, rightTrim: playerItem.duration)
        self.player?.isMuted = true
        videoGravity = .resize
        
        addObservers()
    }
    
    func setFilter(_ filter: YPFilter) {
        self.filter = filter
        self.player?.currentItem?.videoComposition = buildVideoComposition(filter: filter)
    }
    
    private func buildVideoComposition(filter: YPFilter) -> AVVideoComposition? {
        guard let applier = filter.applier else {
            return nil
        }

        let context = CIContext(eaglContext: EAGLContext(api: .openGLES3)!)
        return AVVideoComposition(asset: player!.currentItem!.asset) { (request) in
            let source = request.sourceImage
            request.finish(with: applier(source)!, context: context)
        }
    }
    
    func setRate(_ rate: Float) {
        self.player?.rate = rate
        self.currentRate = rate
    }
    
    
    func play() {
        self.player?.rate = currentRate
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
        let observeInterval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: observeInterval,
                                                           queue: .main) {
                                                            [weak self] time in                                                                                             self?.observePlaybackStatus()
        }

        loopObserver = NotificationCenter.default.addObserver(forName: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { (notif) in
            guard let player = self.player, let currentItem = player.currentItem else { return }
            if currentItem.currentTime() == currentItem.forwardPlaybackEndTime {
                player.seek(to: self.trimPosition.leftTrim)
                player.playImmediately(atRate: self.currentRate)
            }
        }
        
        self.player?.currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: nil)
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
    
    func observePlaybackStatus() {
        guard let currentItem = self.player?.currentItem else {return}
        
        let currentTime = currentItem.currentTime()
        showLoading(currentItem.isPlaybackBufferEmpty)
        if self.player!.timeControlStatus == .playing {
            if currentItem.isPlaybackLikelyToKeepUp {
                previewView.isHidden = true
                self.videoViewControllerDelegate?.onProgressChanged(progress:
                    currentTime)
                pause()
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
        }
        self.player?.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: nil)
    }
    
    func seek(toProgress progress: CMTime) {
        guard let player = self.player else {
            return
        }

        showLoading(true)
        let tolerance = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(600))
        player.seek(to: progress, toleranceBefore: tolerance, toleranceAfter: tolerance, completionHandler: {success in
        })
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
        
        switch state {
        case .finished(let forceReset):
            var reset:Bool
            if !forceReset {
                reset = currentItem.currentTime() < position.leftTrim || currentItem.currentTime() > position.rightTrim
            } else {
                reset = true
            }
            
            if reset {
                seek(toProgress: position.leftTrim)
            }
            play()
        case .started:
            pause()
        default:
            break
        }
    }
}
