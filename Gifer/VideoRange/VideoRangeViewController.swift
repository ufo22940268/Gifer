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
    var currentItem: AVPlayerItem {
        return player.currentItem!
    }
    @IBOutlet weak var videoController: VideoController!
    var previewAsset: PHAsset!
    var timeObserverToken: Any?
    var loopObserverToken: Any?
    var isDebug:Bool!
    var previewImage: UIImage!
    
    var isSeeking = false
    var chaseTime: CMTime!
    var chaseRightTrim: CMTime?
    var initialLoadingDialog: LoadingDialog?
    @IBOutlet weak var doneItemButton: UIBarButtonItem!
    var loadingIndicator: VideoLoadingIndicator = {
        let indicator = VideoLoadingIndicator()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.isHidden = true
        return indicator
    }()
    
    var downloadTaskId: PHImageRequestID?
    
    var trimPosition: VideoTrimPosition {
        return videoController.trimPosition
    }
    
    var videoCache: VideoCache?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        isDebug = previewImage == nil
        
        DarkMode.enable(in: self)
        setupPreview()
        setupVideoController()
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        if isDebug {
            previewAsset = getTestVideo()
        }
        setSubtitle("加载中...")
        cacheAsset()
    }
    
    private func cacheAsset() {
        initialLoadingDialog = LoadingDialog(label: "正在加载视频")
        initialLoadingDialog?.show(by: self)
        
        let manager = PHImageManager.default()
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .fastFormat
        options.progressHandler = self.onDownloadVideoProgressChanged
        
        if let downloadTaskId = downloadTaskId {
            manager.cancelImageRequest(downloadTaskId)
            self.downloadTaskId = nil
        }
        
        downloadTaskId = manager.requestAVAsset(forVideo: previewAsset, options: options) { (avAsset, _, _) in
            guard let avAsset = avAsset else { return }
            self.videoCache = VideoCache(asset: avAsset, cacheName: "range")
            self.videoCache?.delegate = self
            self.videoCache?.parse(trimPosition: VideoTrimPosition(leftTrim: .zero, rightTrim: avAsset.duration), completion: { (url) in
                self.view.tintAdjustmentMode = .automatic
                self.videoPreviewSection.alpha = 1.0
                self.loadPreview(url: url)
            })
        }
    }

    
    private func setSubtitle(_ subTitle: String) {
        navigationItem.setTwoLineTitle(lineOne: "修剪", lineTwo: subTitle)
    }
    
    private func loadPreview(url: URL) {
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        self.onPreviewLoaded(playerItem: playerItem)
    }
    
    private func onPreviewLoaded(playerItem: AVPlayerItem) {
        self.initialLoadingDialog?.dismiss()
        self.previewController.player = AVPlayer(playerItem: playerItem)
        guard let previewImage = playerItem.asset.copyFirstImage() else { return }
        self.previewImage = previewImage
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
        var showLoading:Bool
        if case AVPlayer.Status.readyToPlay = player.status {
            let percent: Double = ((progress - trimPosition.leftTrim).seconds/trimPosition.galleryDuration.seconds).clamped(to: 0...1)
            videoController.updateSliderProgress(percent: CGFloat(percent))
            showLoading = !currentItem.isPlaybackLikelyToKeepUp
        } else {
            showLoading = false
        }
        
        if showLoading && currentItem.currentTime() != .zero {
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
        if let player = player {
            player.pause()
            unregisterObservers()
        }
        
        if let downloadTaskId = downloadTaskId {
            PHImageManager.default().cancelImageRequest(downloadTaskId)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        videoCache = nil
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
            trimState = .finished(true)
            videoController.scrollReason = .other
        } else if state == .began {
            trimState = .started
            videoController.scrollReason = .slider
        } else {
            trimState = .moving(seekToSlider: false)
        }
        updateTrimPosition(position: position, trimState: trimState)
    }
    
    private func updateTrimPosition(position: VideoTrimPosition, trimState: VideoTrimState, forceSeek: CMTime? = nil) {
        if case .finished(_) = trimState {
            currentItem.cancelPendingSeeks()
            currentItem.forwardPlaybackEndTime = position.rightTrim
            videoController.stickTo(side: nil)
            seekToAndPlay(position: position.leftTrim)
        } else {
            if case .started = trimState {
                player.pause()
            }
            
            if case .initial = trimState {
                currentItem.forwardPlaybackEndTime = position.rightTrim
            }
            
            if let forceSeek = forceSeek, !isSeeking {
                player.pause()
                chaseTime = forceSeek
                chaseRightTrim = position.rightTrim
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
        if let chaseRightTrim = chaseRightTrim {            
            currentItem.forwardPlaybackEndTime = chaseRightTrim
        }
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
        if segue.identifier == "edit", let editVC = segue.destination as? EditViewController, let cachedURL = videoCache?.cachedURL {
            editVC.previewImage = previewImage
            editVC.videoCachedURL = cachedURL
            editVC.initTrimPosition = trimPosition
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
