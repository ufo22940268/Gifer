//
//  VideoRangeViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/19.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit
import Photos

class VideoRangeViewController: UIViewController {
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var videoPreviewSection: UIView!
    var previewController: AVPlayerViewController!
    var player: AVPlayer {
        return previewController.player!
    }
    var currentItem: AVPlayerItem {
        return player.currentItem!
    }
    @IBOutlet weak var videoController: VideoController!
    var previewAsset: PHAsset!
    var timeObserverToken: Any?
    var loopObserverToken: Any?
    
    var trimPosition: VideoTrimPosition {
        return videoController.trimPosition
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPreview()
        setupVideoController()
        previewAsset = getTestVideo()
        loadPreview(phAsset: previewAsset)
    }
    
    private func loadPreview(phAsset: PHAsset) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic
        PHImageManager.default().requestPlayerItem(forVideo: phAsset, options: options) { (playerItem, _) in
            guard let playerItem = playerItem else { return }
            DispatchQueue.main.async {
                //TODO
                self.previewController.player = AVPlayer(playerItem: playerItem)
                self.previewController.player?.play()
                self.previewController.view.translatesAutoresizingMaskIntoConstraints = false
                self.videoController.load(playerItem: playerItem, completion: {
                    
                })
                self.currentItem.forwardPlaybackEndTime = self.videoController.galleryDuration
                self.registerObservers()
            }
        }
    }
    
    private func setupVideoController() {
        videoController.delegate = self
    }
    
    private func registerObservers() {
        self.previewController.player!.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: nil)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
                                                            queue: .main) {
                                                                [weak self] time in
                                                                self?.observePlayProgress(progress: time)
        }
        
        loopObserverToken = NotificationCenter.default.addObserver(forName: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil, using:observerPlayToTheEnd)
    }
    
    private func observerPlayToTheEnd(notification: Notification) {
        player.seek(to: trimPosition.leftTrim)
        player.play()
    }
    
    private func observePlayProgress(progress: CMTime) {
        if case AVPlayer.Status.readyToPlay = player.status {
            videoController.updateSliderProgress(progress)
        }
    }
    
    private func unregisterObservers() {
        self.removeObserver(self.previewController.player!, forKeyPath: #keyPath(AVPlayerItem.status))
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
        }
        
        if let loopObserverToken = loopObserverToken {
            player.removeTimeObserver(loopObserverToken)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.status) {
            let player = object as! AVPlayer
            if case AVPlayer.Status.readyToPlay = player.status {
                let targetSize = AVMakeRect(aspectRatio: CGSize(width: previewAsset.pixelWidth, height: previewAsset.pixelHeight), insideRect: videoPreviewSection.bounds).size
                previewController.view.constraints.findById(id: "width").constant = targetSize.width
                previewController.view.constraints.findById(id: "height").constant = targetSize.height
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        unregisterObservers()
    }
    
    
    func setupPreview() {
        previewController = AVPlayerViewController(nibName: nil, bundle: nil)
        previewController.showsPlaybackControls = false
        videoPreviewSection.addSubview(previewController.view)
        videoPreviewSection.backgroundColor = .black
        NSLayoutConstraint.activate([
            previewController.view.widthAnchor.constraint(equalToConstant: videoPreviewSection.bounds.width).with(identifier: "width"),
            previewController.view.heightAnchor.constraint(equalToConstant: videoPreviewSection.bounds.height).with(identifier: "height"),
            previewController.view.centerXAnchor.constraint(equalTo: videoPreviewSection.centerXAnchor),
            previewController.view.centerYAnchor.constraint(equalTo: videoPreviewSection.centerYAnchor)
        ])
        didMove(toParent: previewController)
    }
}

extension VideoRangeViewController: VideoControllerDelegate {
    
    /// Change be gallery slider
    func onTrimChanged(begin: CGFloat, end: CGFloat, state: UIGestureRecognizer.State) {
        let duration = currentItem.duration
        let left = CMTimeMultiplyByFloat64(duration, multiplier: Float64(begin))
        let right = CMTimeMultiplyByFloat64(duration, multiplier: Float64(end))
        let position: VideoTrimPosition = VideoTrimPosition(leftTrim: left, rightTrim: right)
        videoController.scrollTo(position: position)
        
        var trimState: VideoTrimState
        if state == .ended {
            trimState = .finished(true)
        } else if state == .began {
            trimState = .started
            videoController.scrollReason = .slider
        } else {
            trimState = .moving
        }
        
        updateTrimPosition(position: position, state: trimState)
        
        if state == .ended {
            videoController.scrollReason = .other
        }
    }
    
    private func updateTrimPosition(position: VideoTrimPosition, state: VideoTrimState) {
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
                player.seek(to: position.leftTrim)
            }
            player.play()
        case .started:
            player.pause()
        default:
            break
        }
    }
    
    /// Change by gallery scroller
    func onTrimChanged(position: VideoTrimPosition, state: VideoTrimState) {
        if case .started = state {
            videoController.hideSlider(true)
        }

        if currentItem.duration.seconds > 0 {
            let begin: CGFloat = CGFloat(position.leftTrim.seconds/currentItem.duration.seconds)
            let end: CGFloat = CGFloat(position.rightTrim.seconds/currentItem.duration.seconds)
            videoController.gallerySlider.updateSlider(begin: begin, end: end, galleryDuration: position.galleryDuration)
        }
        
        updateTrimPosition(position: position, state: state)
    }
    
    func onSlideVideo(state: SlideState, progress: CMTime!) {
        switch state {
        case .begin:
            player.pause()
        case .slide:
            player.seek(to: progress)
        case .end:
            break
        }
    }
}


