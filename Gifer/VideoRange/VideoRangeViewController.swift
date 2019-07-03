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
    func copyFirstImage() -> UIImage? {
        let generator = AVAssetImageGenerator(asset: self)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = UIScreen.main.bounds.size
        if let image = try? generator.copyCGImage(at: CMTime.zero, actualTime: nil) {
            return UIImage(cgImage: image)
        } else {
            return nil
        }
    }
    
    func videoAssetComposition() -> AVMutableComposition {
        let composition = AVMutableComposition()
        composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let videoTrack = composition.tracks(withMediaType: .video).last!
        videoTrack.preferredTransform = self.tracks(withMediaType: .video).first!.preferredTransform
        try! composition.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: self.duration), of: self, at: .zero)
        return composition
    }
}

class VideoRangeViewController: UIViewController {
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var videoPreviewSection: UIView!
    var previewController: AVPlayerViewController!
    var player: AVPlayer! {
        return previewController.player ?? nil
    }
    var isInControl: Bool = false
    var currentItem: AVPlayerItem! {
        if let player = player, let currentItem = player.currentItem {
            return currentItem
        } else {
            return nil
        }
    }
    @IBOutlet weak var videoController: VideoController!
    var previewAsset: PHAsset!
    var timeObserverToken: Any?
    var loopObserverToken: Any?
    var isDebug:Bool!
    
    var isSeeking = false
    var chaseTime: CMTime!
    var chaseRightTrim: CMTime?
    var initialLoadingDialog: LoadingDialog?
    @IBOutlet weak var doneItemButton: UIBarButtonItem!
    var loadingIndicator: VideoLoadingIndicator = {
        let indicator = VideoLoadingIndicator()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    var trimPosition: VideoTrimPosition {
        return videoController.trimPosition
    }
    
    var videoCache: VideoCache?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        isDebug = false
        
        DarkMode.enable(in: self)
        setupPreview()
        setupVideoController()
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        if isDebug {
            previewAsset = getTestVideo()
        }
        setSubtitle("加载中...")
        loadAsset()
    }
    
    private func loadAsset() {
        let manager = PHImageManager.default()
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .fastFormat
        options.progressHandler = self.onDownloadVideoProgressChanged
        kdebug_signpost_start(1, 0, 0, 0, 0)
        manager.requestPlayerItem(forVideo: previewAsset, options: options) { (playerItem, _) in
            guard let playerItem = playerItem else { return }
            DispatchQueue.main.async {
                self.view.tintAdjustmentMode = .automatic
                self.videoPreviewSection.alpha = 1.0
                self.loadPreview(playerItem: playerItem)
            }
        }
    }

    private func loadPreview(playerItem: AVPlayerItem) {
        self.previewController.player = AVPlayer(playerItem: playerItem)
        self.previewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.videoController.load(playerItem: playerItem, gifMaxDuration: 20, completion: {
            self.setSubtitle(position: self.trimPosition)
            self.doneItemButton.isEnabled = true
        })
        self.currentItem.forwardPlaybackEndTime = self.videoController.galleryDuration
        self.registerObservers()
        
        player.volume = 0
        player.play()
        kdebug_signpost_end(1, 0, 0, 0, 0)
    }
    
    private func setSubtitle(_ subTitle: String) {
        navigationItem.setTwoLineTitle(lineOne: "修剪", lineTwo: subTitle)
    }

    private func setupVideoController() {
        videoController.delegate = self
    }
    
    private func registerObservers() {
        guard previewController.player != nil && timeObserverToken == nil else {
            return
        }

        currentItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new], context: nil)
        currentItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), options: [.new], context: nil)

        let interval = UIDevice.isSimulator ? 0.5 : 0.01
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: interval, preferredTimescale: 600),
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
        player.seek(to: position) { (success) in
            self.player.play()
        }
    }
    
    private func observePlayProgress(progress: CMTime) {
        if case AVPlayer.Status.readyToPlay = player.status {
            let percent: Double = ((progress - trimPosition.leftTrim).seconds/trimPosition.galleryDuration.seconds).clamped(to: 0...1)
            videoController.updateSliderProgress(percent: CGFloat(percent))
        }
        
        if currentItem != nil && currentItem.isPlaybackLikelyToKeepUp {
            loadingIndicator.dismiss()
        } else {
            loadingIndicator.show()
        }
    }
        
    private func unregisterObservers() {
        currentItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        currentItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp))
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
        } else if keyPath == #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp) {
            print("likely to keepup: \(currentItem.isPlaybackLikelyToKeepUp)")
        }
    }
    
    @IBAction func onDismiss() {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if previewController.player != nil {
            player.play()
        }
        registerObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let player = player {
            player.pause()
        }
        unregisterObservers()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        videoCache = nil
        if isMovingFromParent {
            destroy()
        }
    }
    
    func destroy() {
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
    
    func onAttachChanged(component: OverlayComponent, trimPosition: VideoTrimPosition) {
        
    }
    
    private func setSubtitle(position: VideoTrimPosition) {
        let text = position.leftTrim.formatTime() + " ~ " + position.rightTrim.formatTime()
        setSubtitle(text)
    }
    
    var duration: CMTime {
        return player.currentItem!.duration
    }
    
    func onTrimChangedByScrollInGallery(trimPosition position: VideoTrimPosition, state: VideoTrimState, currentPosition: CMTime) {
        videoController.gallerySlider.sync(galleryRange: videoController.galleryRangeInSlider)
        videoController.stickTo(side: .left)
        updateTrimPosition(position: position, trimState: state, forceSeek: position.leftTrim)
    }
    
    /// Change be gallery slider
    func onTrimChangedByGallerySlider(state: UIGestureRecognizer.State, scrollTime: CMTime, scrollDistance: CGFloat) {
        var position = trimPosition
        position.scrollBy(scrollTime)
        videoController.layoutIfNeeded()
        var galleryRange = videoController.galleryRangeInSlider
        galleryRange.scroll(by: scrollTime)
        
        videoController.galleryScrollTo(galleryRange: galleryRange)
        updateTrimPosition(position: position, state: state)
    }
    
    private func updateTrimPosition(position: VideoTrimPosition, state: UIGestureRecognizer.State) {
        var trimState: VideoTrimState
        if state == .ended {
            isInControl = false
            trimState = .finished(true)
            videoController.scrollReason = .other
        } else if state == .began {
            isInControl = true
            trimState = .started
            videoController.scrollReason = .slider
        } else {
            trimState = .moving(seekToSlider: false)
        }
        updateTrimPosition(position: position, trimState: trimState)
    }
    
    private func updateTrimPosition(position: VideoTrimPosition, trimState: VideoTrimState, forceSeek: CMTime? = nil) {
        if case .finished(_) = trimState {
            isInControl = false
            currentItem.cancelPendingSeeks()
            currentItem.forwardPlaybackEndTime = position.rightTrim
            videoController.stickTo(side: nil)
            seekToAndPlay(position: position.leftTrim)
        } else {
            if case .started = trimState {
                isInControl = true
                player.pause()
            }
            
            if case .initial = trimState {
                currentItem.forwardPlaybackEndTime = position.rightTrim
            }
            
            if let forceSeek = forceSeek, !isSeeking {
                player.pause()
                chaseTime = forceSeek
                trySeekToChaseTime()
            }
        }        
        setSubtitle(position: position)
    }
    
    func trySeekToChaseTime() {
        if player.currentItem!.status == .readyToPlay {
            actualSeekToChaseTime()
        }
    }
    
    func actualSeekToChaseTime() {
        isSeeking = true
        let seekTimeInProgress = self.chaseTime!
        player.currentItem?.seek(to: seekTimeInProgress, toleranceBefore: .zero, toleranceAfter: .zero) {_ in
            self.isSeeking = false
            if self.chaseTime != seekTimeInProgress {
                self.trySeekToChaseTime()
            }
        }
    }
    
    func onTrimChangedByTrimer(trimPosition: VideoTrimPosition, state: VideoTrimState, side: TrimController.Side?) {
        guard let side = side else { return }
        let position = trimPosition
        videoController.stickTo(side: side)
        updateTrimPosition(position: position, trimState: state, forceSeek: side == .right ? trimPosition.rightTrim : trimPosition.leftTrim)
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
            editVC.initTrimPosition = trimPosition
            editVC.videoAsset = previewAsset
        }
    }
}

extension VideoRangeViewController: VideoCacheDelegate {
    func onParsingProgressChanged(progress: CGFloat) {
        view.tintAdjustmentMode = .dimmed
    }
    
    func onDownloadVideoProgressChanged(_ progress: Double, e: Error?, p: UnsafeMutablePointer<ObjCBool>, i: [AnyHashable : Any]?) {
        view.tintAdjustmentMode = .dimmed
    }
}

extension VideoRangeViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
