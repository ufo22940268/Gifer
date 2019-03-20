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

extension CMTime {
    func formatTime() -> String {
        let minutes = Int(self.seconds/60)
        let seconds = Int(self.seconds)%60
        return String(format: "%02i:%02i", minutes, seconds)
    }
}

extension AVAsset {
    func copyFirstImage() -> UIImage {
        let generator = AVAssetImageGenerator(asset: self)
        generator.maximumSize = UIScreen.main.bounds.size
        return UIImage(cgImage: try! generator.copyCGImage(at: CMTime.zero, actualTime: nil))
    }
}

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
    var isDebug:Bool!
    var previewImage: UIImage!
    
    @IBOutlet weak var doneItemButton: UIBarButtonItem!
    var loadingIndicator: VideoLoadingIndicator = {
        let indicator = VideoLoadingIndicator()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.show()
        return indicator
    }()
    
    var trimPosition: VideoTrimPosition {
        return videoController.trimPosition
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        isDebug = previewImage == nil
        
        DarkMode.enable(in: self)
        setupPreview()
        setupVideoController()
        previewAsset = getTestVideo()
        loadPreview(phAsset: previewAsset)
        
        setSubtitle("加载中...")
    }
    
    private func setSubtitle(_ subTitle: String) {
        navigationItem.setTwoLineTitle(lineOne: "修剪", lineTwo: subTitle)
    }
    
    private func loadPreview(phAsset: PHAsset) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic
        PHImageManager.default().requestPlayerItem(forVideo: phAsset, options: options) { (playerItem, _) in
            guard let playerItem = playerItem else { return }
            DispatchQueue.main.async {
                self.onPreviewLoaded(playerItem: playerItem)
            }
            
        }
    }
    
    private func onPreviewLoaded(playerItem: AVPlayerItem) {
        self.previewController.player = AVPlayer(playerItem: playerItem)
        self.previewImage = playerItem.asset.copyFirstImage()
        self.previewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.videoController.load(playerItem: playerItem, gifMaxDuration: 20, completion: {
            self.setSubtitle(position: self.trimPosition)
            self.doneItemButton.isEnabled = true
        })
        self.currentItem.forwardPlaybackEndTime = self.videoController.galleryDuration
        self.registerObservers()
        
        player.volume = 0
        player.play()
    }
    
    private func setupVideoController() {
        videoController.delegate = self
    }
    
    private func registerObservers() {
        guard previewController.player != nil && timeObserverToken == nil else {
            return
        }
        
        currentItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new], context: nil)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
                                                            queue: .main) {
                                                                [weak self] time in
                                                                self?.observePlayProgress(progress: time)
        }
        
        loopObserverToken = NotificationCenter.default.addObserver(forName: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil, using:observerPlayToTheEnd)
    }
    
    private func observerPlayToTheEnd(notification: Notification) {
        seekToAndPlay(position: trimPosition.leftTrim)
    }
    
    private func seekToAndPlay(position: CMTime) {
        loadingIndicator.show()
        player.seek(to: position, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { (_) in
            self.player.play()
        }
    }
    
    private func observePlayProgress(progress: CMTime) {
        var showLoading:Bool
        if case AVPlayer.Status.readyToPlay = player.status {
            videoController.updateSliderProgress(progress)
            showLoading = !currentItem.isPlaybackLikelyToKeepUp
        } else {
            showLoading = false
        }
        
        if showLoading {
            loadingIndicator.show()
        } else {
            loadingIndicator.dismiss()
        }
    }
    
    
    private func unregisterObservers() {
        currentItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        
        if let loopObserverToken = loopObserverToken {
            NotificationCenter.default.removeObserver(loopObserverToken)
            self.loopObserverToken = nil
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.status) {
            if case AVPlayer.Status.readyToPlay = player.status {
                let targetSize = AVMakeRect(aspectRatio: CGSize(width: previewAsset.pixelWidth, height: previewAsset.pixelHeight), insideRect: videoPreviewSection.bounds).size
                previewController.view.constraints.findById(id: "width").constant = targetSize.width
                previewController.view.constraints.findById(id: "height").constant = targetSize.height
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        registerObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        unregisterObservers()
    }
    
    func setupPreview() {
        previewController = AVPlayerViewController(nibName: nil, bundle: nil)
        previewController.showsPlaybackControls = false
        videoPreviewSection.addSubview(previewController.view)
        videoPreviewSection.backgroundColor = .black
        previewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            previewController.view.widthAnchor.constraint(equalToConstant: videoPreviewSection.bounds.width).with(identifier: "width"),
            previewController.view.heightAnchor.constraint(equalToConstant: videoPreviewSection.bounds.height).with(identifier: "height"),
            previewController.view.centerXAnchor.constraint(equalTo: videoPreviewSection.centerXAnchor),
            previewController.view.centerYAnchor.constraint(equalTo: videoPreviewSection.centerYAnchor)
        ])
        didMove(toParent: previewController)
        
        videoPreviewSection.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.widthAnchor.constraint(equalTo: videoPreviewSection.widthAnchor),
            loadingIndicator.heightAnchor.constraint(equalTo: videoPreviewSection.heightAnchor),
            loadingIndicator.centerXAnchor.constraint(equalTo: videoPreviewSection.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: videoPreviewSection.centerYAnchor)
            ])
    }
}

extension VideoRangeViewController: VideoControllerDelegate {
    
    private func setSubtitle(position: VideoTrimPosition) {
        let text = position.leftTrim.formatTime() + " ~ " + position.rightTrim.formatTime()
        setSubtitle(text)
    }
    
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
        
        setSubtitle(position: position)
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
                seekToAndPlay(position: position.leftTrim)
            } else {
                player.play()
            }
        case .started:
            player.pause()
        default:
            break
        }
        
        setSubtitle(position: position)
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
            seekToAndPlay(position: progress)
        case .end:
            break
        }
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "edit", let editVC = segue.destination as? EditViewController {
            editVC.previewImage = previewImage
        }
    }
}


