//
//  EditViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/11/12.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit
import Photos

enum ToolbarItemState {
    case normal, highlight
    
    func updateOptionMenuContainer(container: UIView) {
        switch self {
        case .normal:
            container.isHidden = true
        case .highlight:
            container.isHidden = false
        }
    }
}

struct ToolbarItemStyle {
    
    let highlightBackground: UIImage = #imageLiteral(resourceName: "bar-item-background.png")
    let highlightTint: UIColor = UIColor.black
    var normalBackground: UIImage? = nil
    let normalTint: UIColor = UIColor.white
    
    init() {
        let renderer: UIGraphicsImageRenderer = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 50))
        normalBackground = renderer.image { (context) in
            UIColor.clear.setFill()
            context.fill(renderer.format.bounds)
        }
    }
    
    func setup(_ barItem: UIBarButtonItem, state: ToolbarItemState) {
        switch state {
        case .normal:
            barItem.tintColor = self.normalTint
            barItem.setBackgroundImage(self.normalBackground, for: .normal, barMetrics: .default)
        case .highlight:
            barItem.tintColor = self.highlightTint
            barItem.setBackgroundImage(self.highlightBackground, for: .normal, barMetrics: .default)
        }
    }
}

@objc enum ToolbarItem: Int, CaseIterable {
    case playSpeed
    case crop
    case filters
    case sticker
}

extension NSLayoutConstraint {
    func with(identifier: String) -> NSLayoutConstraint {
        self.identifier = identifier
        return self
    }
}

struct ToolbarItemInfo {
    var index: ToolbarItem
    var state: ToolbarItemState
    var barItem: UIBarButtonItem
}

extension UIViewController {
    func makeToast(message: String, completion: @escaping () -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {_ in completion()}))
        present(alertController, animated: true, completion: nil)
    }
}

class EditViewController: UIViewController {
    
    var videoVC: VideoViewController!
    @IBOutlet weak var videoController: VideoController!
    var gifOverlayVC: GifOverlayViewController!
    
    var videoContainer: UIView!
    @IBOutlet var toolbar: UIToolbar!
    
    var optionMenu: OptionMenu!
    var optionMenuTopConstraint: NSLayoutConstraint!
    var optionMenuBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var videoLoadingIndicator: UIActivityIndicatorView!
    var videoAsset: PHAsset!
    var loadingDialog: LoadingDialog?
    
    var predefinedToolbarItemStyle = ToolbarItemStyle()
    var toolbarItemInfos = [ToolbarItemInfo]()
    
    @IBOutlet weak var videoPlayerSection: VideoPlayerSection!
    var playSpeedView: PlaySpeedView {
        return optionMenu.playSpeedView
    }

    @IBOutlet weak var cropContainer: CropContainer!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var shareItem: UIBarButtonItem!
    
    @IBOutlet weak var controlToolbar: ControlToolbar!
    var defaultGifOptions: GifGenerator.Options?
    
    var controlToolbarFunctionalIndexes: [Int] {
        return ToolbarItem.allCases.map{$0.rawValue}
    }
    
    override func loadView() {
        super.loadView()
    }
    
    override func viewDidLoad() {
        view.backgroundColor = #colorLiteral(red: 0.0862745098, green: 0.09019607843, blue: 0.09411764706, alpha: 1)

        let singleLaunched = isDebug
        if singleLaunched {
            videoAsset = getTestVideo()
        }
        setupVideoContainer()
        setupControlToolbar()
        
        if singleLaunched {
            loadVideo()
        }
    }
    
    func setupVideoContainer() {
        videoContainer = UIView()
        videoContainer.translatesAutoresizingMaskIntoConstraints = false
        cropContainer.setupCover()
        cropContainer.addContentView(videoContainer)
        videoPlayerSection.cropContainer = cropContainer
        
        videoVC = storyboard!.instantiateViewController(withIdentifier: "videoViewController") as? VideoViewController
        addChild(videoVC)
        videoContainer.addSubview(videoVC.view)
        videoVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoVC.view.leadingAnchor.constraint(equalTo: videoContainer.leadingAnchor),
            videoVC.view.topAnchor.constraint(equalTo: videoContainer.topAnchor),
            videoVC.view.trailingAnchor.constraint(equalTo: videoContainer.trailingAnchor),
            videoVC.view.bottomAnchor.constraint(equalTo: videoContainer.bottomAnchor),
            videoVC.view.widthAnchor.constraint(equalTo: videoContainer.widthAnchor),
            videoVC.view.heightAnchor.constraint(equalTo: videoContainer.heightAnchor)
            ])
        videoVC.didMove(toParent: self)
        
        setupGifOverlay()
        
        let previewView = VideoPreviewView()
        previewView.translatesAutoresizingMaskIntoConstraints = false
        videoPlayerSection.insertSubview(previewView, belowSubview: videoLoadingIndicator)
        NSLayoutConstraint.activate([
            previewView.heightAnchor.constraint(equalTo: videoPlayerSection.heightAnchor),
            previewView.widthAnchor.constraint(equalTo: videoPlayerSection.widthAnchor),
            previewView.centerXAnchor.constraint(equalTo: videoPlayerSection.centerXAnchor),
            previewView.centerYAnchor.constraint(equalTo: videoPlayerSection.centerYAnchor)
            ])
        previewView.backgroundColor = UIColor.black
        videoVC.previewView = previewView
    }
    
    var isDebug: Bool {
        get {
            return videoAsset == nil
        }
    }
    
    private func setupGifOverlay() {
        gifOverlayVC = storyboard!.instantiateViewController(withIdentifier: "gifOverlay") as! GifOverlayViewController
        addChild(gifOverlayVC)
        
        cropContainer.addSubview(gifOverlayVC.view)
        gifOverlayVC.enableModification(false)
        gifOverlayVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gifOverlayVC.view.leadingAnchor.constraint(equalTo: videoContainer.leadingAnchor),
            gifOverlayVC.view.trailingAnchor.constraint(equalTo: videoContainer.trailingAnchor),
            gifOverlayVC.view.topAnchor.constraint(equalTo: videoContainer.topAnchor),
            gifOverlayVC.view.bottomAnchor.constraint(equalTo: videoContainer.bottomAnchor)
            ])
        didMove(toParent: gifOverlayVC)
    }
    
    fileprivate func setupControlToolbar() {
        optionMenu = OptionMenu()
        stackView.addSubview(optionMenu)
        optionMenu.isHidden = true
        optionMenuBottomConstraint = optionMenu.bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        optionMenuTopConstraint = optionMenu.topAnchor.constraint(equalTo: stackView.bottomAnchor)
        NSLayoutConstraint.activate([
            optionMenu.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            optionMenu.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            optionMenuTopConstraint
            ])
        optionMenu.delegate = self
        controlToolbar.toolbarDelegate = self
    }
    
    var previewView: UIView? {
        return videoVC.previewView
    }
    
    var displayVideoRect: CGRect {
        let rect = videoPlayerSection.bounds
        return AVMakeRect(aspectRatio: CGSize(width: self.videoAsset.pixelWidth, height: self.videoAsset.pixelHeight), insideRect: rect)
    }
    
    func loadVideo() {
        videoLoadingIndicator.isHidden = false
        
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .fastFormat
        
        PHImageManager.default().requestPlayerItem(forVideo: self.videoAsset, options: options) { [weak self] (playerItem, info) in
            guard let _ = self else { return }
            if let playerItem = playerItem {
                DispatchQueue.main.async { [weak self] in
                    guard let this = self else { return }
                    
                    if this.getPreviewImage() == nil {
                        let cgImage = try! AVAssetImageGenerator(asset: playerItem.asset).copyCGImage(at: CMTime.zero, actualTime: nil)
                        this.setPreviewImage(UIImage(cgImage: cgImage))
                    }
                    
                    this.optionMenu.setPreviewImage(this.getPreviewImage()!.resizeImage(60, opaque: false))
                    
                    this.cropContainer.superview!.constraints.findById(id: "width").isActive = false
                    this.cropContainer.superview!.constraints.findById(id: "height").isActive = false
                    this.cropContainer.videoSize = CGSize(width: this.videoAsset.pixelWidth, height: this.videoAsset.pixelHeight)
                    this.cropContainer.widthAnchor.constraint(equalToConstant: this.displayVideoRect.width).with(identifier: "width").isActive = true
                    this.cropContainer.heightAnchor.constraint(equalToConstant: this.displayVideoRect.height).with(identifier: "height").isActive = true
                    
                    this.cropContainer.setupVideo(frame: this.displayVideoRect)
                    
                    this.videoVC.load(playerItem: playerItem)
                    this.videoVC.videoViewControllerDelegate = this
                    this.setupFiltersSection()
                }
            }
        }
    }
    
    func setupFiltersSection() {
    }
    
    func setPreviewImage(_ image: UIImage) {
        videoVC.previewImage = image
        videoVC.previewView.image = image
    }
    
    func getPreviewImage() -> UIImage? {
        return videoVC.previewImage
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "emberVideo" {
            videoVC = segue.destination as? VideoViewController
        }
    }
    
    var currentGifOption: GifGenerator.Options {
        let trimPosition = videoController.trimPosition
        let startProgress = trimPosition.leftTrim
        let endProgress = trimPosition.rightTrim
        let speed = Float(playSpeedView.currentSpeedSnapshot)
        let cropArea = cropContainer.cropArea
        return GifGenerator.Options(start: startProgress, end: endProgress, speed: speed, cropArea: cropArea, filter: videoVC.filter)
    }
    
    private func startSharing(for type: ShareType) {
        guard let asset = videoVC.player?.currentItem?.asset else {
            return
        }
        showLoadingWhenExporting(true)
        let shareManager: ShareManager = ShareManager(asset: asset, options: currentGifOption)
        shareManager.share { gif in
            self.showLoadingWhenExporting(false)
            
            switch type {
            case .wechat:
                shareManager.shareToWechat(video: gif, complete: { (success) in                    
                    self.dismiss(animated: true, completion: nil)
                })
            case .photo:
                shareManager.saveToPhoto(gif: gif) {success in
                    let alert = UIAlertController(title: nil, message: "保存成功", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "前往相册", style: .default, handler: { (_) in
                        UIApplication.shared.open(URL(string:"photos-redirect://")!)
                    }))
                    alert.addAction(UIAlertAction(title: "返回", style: .default, handler: { (_) in
                        self.dismiss(animated: true, completion: nil)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func onShare(_ sender: Any) {
        videoVC.pause()
        let shareController = ShareDialogController(shareHandler: startSharing)
        shareController.present(by: self)
    }
    
    private func prompt(_ text: String) {
        let alert = UIAlertController(title: nil, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func showLoadingWhenExporting(_ show: Bool) {
        showLoading(show, label: "导出中...")
    }

    private func showLoading(_ show: Bool, label: String) {
        if (show) {
            if loadingDialog == nil || !(loadingDialog!.isShowing)  {
                loadingDialog = LoadingDialog(label: label)
                loadingDialog!.show(by: self)
            }
        } else {
            loadingDialog?.dismiss()
        }
    }
    
    fileprivate func play() {
        videoVC.play()
    }
    
    fileprivate func pause() {
        videoVC.pause()
    }
    
    func onVideoSectionFrameUpdated() {
        guard let width = cropContainer.constraints.first(where: {$0.identifier == "width"}),
            let height = cropContainer.constraints.first(where: {$0.identifier == "height"}) else {
            return
        }
        let rect = videoRect
        width.constant = rect.width
        height.constant = rect.height
        cropContainer.updateWhenVideoSizeChanged(videoSize: rect.size)
    }
    
    @IBAction func onCancel(_ sender: Any) {
        if defaultGifOptions == nil || defaultGifOptions! == currentGifOption {
            dismiss(animated: true, completion: nil)
        } else {
            ConfirmToDismissDialog().present(by: self) {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(onResume), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onStop), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @objc func onResume() {
        videoVC.play()
    }
    
    @objc func onStop() {
        videoVC.stop()
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        videoController.dismissed = true
        videoVC.dismissed = true
    }
}

extension EditViewController: VideoViewControllerDelegate {
    
    var videoRect: CGRect {
        return AVMakeRect(aspectRatio: videoVC.videoBounds.size, insideRect: CGRect(origin: CGPoint.zero, size: cropContainer.superview!.frame.size))
    }
    
    var isVideoReady: Bool {
        guard let item = videoVC.player?.currentItem else { return false }
        return item.status == .readyToPlay
    }
    
    func onVideoReady(controller: AVPlayerViewController) {
        self.videoController.delegate = self
        self.videoController.load(playerItem: videoVC.player!.currentItem!) {
            self.enableControlOptions()
            self.videoController.layoutIfNeeded()
            self.onTrimChanged(position: self.videoController.trimPosition, state: .initial)
            self.videoVC.play()
            
            self.defaultGifOptions = self.currentGifOption
        }
    }
    
    private func enableControlOptions() {
        controlToolbar.enableItems(true)
    }
    
    func onBuffering(_ inBuffering: Bool) {
        videoLoadingIndicator.isHidden = !inBuffering
    }
    
    func onProgressChanged(progress: CMTime) {
        guard isVideoReady else { return }
        videoController.updateSliderProgress(progress)
    }
    
    func updatePlaybackStatus(_ status: AVPlayer.TimeControlStatus) {
    }
}

extension EditViewController: VideoControllerDelegate {
    
    /// Change be gallery slider
    ///
    /// - Parameters:
    ///   - begin: Left progress of gallery view.
    ///   - end: Right progress of gallery view
    func onTrimChanged(begin: CGFloat, end: CGFloat, state: UIGestureRecognizer.State) {
        guard let duration = videoVC.player?.currentItem?.duration, duration.seconds > 0 else { return }

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

        videoVC.updateTrim(position: position, state: trimState)
        
        if state == .ended {
            videoController.scrollReason = .other
        }
    }

    /// Change by gallery container scrolling.
    func onTrimChanged(position: VideoTrimPosition, state: VideoTrimState) {
        if case .started = state {
            videoController.hideSlider(true)
        }
        guard let currentItem = videoVC.player?.currentItem else { return }
        if currentItem.duration.seconds > 0 {
            let begin: CGFloat = CGFloat(position.leftTrim.seconds/currentItem.duration.seconds)
            let end: CGFloat = CGFloat(position.rightTrim.seconds/currentItem.duration.seconds)
            videoController.gallerySlider.updateSlider(begin: begin, end: end)
        }
        videoVC.updateTrim(position: position, state: state)
    }
    
    func onSlideVideo(state: SlideState, progress: CMTime!) {
        switch state {
        case .begin:
            pause()
        case .slide:
            self.videoVC.seek(toProgress: progress)
        case .end:
            break
        }
    }
}

extension EditViewController: OptionMenuDelegate {
    
    func onSelect(sticker: Sticker) {
        gifOverlayVC.addSticker(sticker)
    }
    
    func onCropSizeSelected(size: CropSize) {
        switch size.type {
        case .ratio:
            cropContainer.updateCroppingStatus(.adjustCrop)
            UIView.animate(withDuration: 0.3) {
                self.cropContainer.gridRulerView.isGridChanged = false
                self.cropContainer.adjustTo(ratio: size.ratio)
                self.videoPlayerSection.layoutIfNeeded()
            }
        case .free:
            cropContainer.updateCroppingStatus(.adjustCrop)
            UIView.animate(withDuration: 0.3) {
                self.cropContainer.gridRulerView.isGridChanged = false
                self.cropContainer.adjustTo(ratio: self.cropContainer.videoSize!)
                self.videoPlayerSection.layoutIfNeeded()
            }
        }
    }
    
    private func dismissOptionMenu() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.optionMenuBottomConstraint.isActive = false
            self.optionMenuTopConstraint.isActive = true
            self.stackView.setCustomSpacing(0, after: self.videoPlayerSection)
            self.stackView.layoutIfNeeded()
            self.cropContainer.updateWhenContainerSizeChanged(containerBounds: self.videoPlayerSection.bounds)
            self.stackView.layoutIfNeeded()
        }) { (_) in
            self.optionMenu.isHidden = true
        }
    }
    
    func onPromptDismiss(toolbarItem: ToolbarItem, commitChange: Bool) {
        switch toolbarItem {
        case .crop:
            if !commitChange {
                cropContainer.resetCropArea()
            }
            self.cropContainer.updateCroppingStatus(.normal)
            break
        case .sticker:
            gifOverlayVC.enableModification(false)
            if !commitChange {
                gifOverlayVC.removeAllStickers()
            }
        default:
            break
        }
        dismissOptionMenu()
    }
    
    func onPreviewSelected(filter: YPFilter) {
        videoVC.setFilter(filter)
    }
    
    func onRateChanged(_ rate: Float) {
        videoVC.setRate(rate)
    }
}

extension EditViewController: ControlToolbarDelegate {
    
    func showOptionMenu(for toolbarItem: ToolbarItem) {
        optionMenu.isHidden = false
        optionMenu.attach(menuType: toolbarItem)
        optionMenu.layoutIfNeeded()
        UIView.animate(withDuration: 0.175, delay: 0, options: [.curveEaseIn, .transitionCrossDissolve], animations: {
            self.optionMenuTopConstraint.isActive = false
            self.optionMenuBottomConstraint.isActive = true
            let heightChanges = self.optionMenu.bounds.height - self.controlToolbar.bounds.height
            self.stackView.setCustomSpacing(heightChanges, after: self.videoPlayerSection)
            self.stackView.layoutIfNeeded()
            self.cropContainer.updateWhenContainerSizeChanged(containerBounds: self.videoPlayerSection.bounds)
            self.stackView.layoutIfNeeded()
        }, completion: nil)
    }
    
    func onCropItemClicked() {
        showOptionMenu(for: .crop)
        self.cropContainer.updateCroppingStatus(.adjustCrop)
    }
    
    func onFiltersItemClicked() {
        showOptionMenu(for: .filters)
    }
    
    func onPlaySpeedItemClicked() {
        showOptionMenu(for: .playSpeed)
    }
    
    func onStickerItemClicked() {
        gifOverlayVC.enableModification(true)
        showOptionMenu(for: .sticker)
    }
}
