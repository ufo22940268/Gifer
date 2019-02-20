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

enum ToolbarItemIndex: Int, CaseIterable {
    case playSpeed = 2
    case crop = 4
    case filters = 6
}

extension NSLayoutConstraint {
    func with(identifier: String) -> NSLayoutConstraint {
        self.identifier = identifier
        return self
    }
}

struct ToolbarItemInfo {
    var index: ToolbarItemIndex
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
    
    var videoContainer: UIView!
    @IBOutlet var toolbar: UIToolbar!
    
    @IBOutlet weak var optionMenu: OptionMenu!
    @IBOutlet weak var controlToolbar: UIToolbar!
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
        
    var controlToolBarFuntionalItems: [UIBarButtonItem] {
        let validIndexes = ToolbarItemIndex.allCases.map({$0.rawValue})
        return controlToolbar.items!.enumerated().filter({t in validIndexes.contains(t.0)}).map({$0.1})
    }
    
    var controlToolbarFunctionalIndexes: [Int] {
        return ToolbarItemIndex.allCases.map{$0.rawValue}
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
        
        let previewView = VideoPreviewView()
        previewView.translatesAutoresizingMaskIntoConstraints = false
        videoPlayerSection.insertSubview(previewView, belowSubview: videoLoadingIndicator)
        NSLayoutConstraint.activate([
            previewView.heightAnchor.constraint(equalTo: videoPlayerSection.heightAnchor, constant: -32),
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
    
    fileprivate func setupControlToolbar() {
        optionMenu.delegate = self
        for (index, item) in controlToolbar.items!.enumerated().filter({controlToolbarFunctionalIndexes.contains($0.offset)}) {
            let info = ToolbarItemInfo(index: ToolbarItemIndex(rawValue: index)!, state: .normal, barItem: item)
            toolbarItemInfos.append(info)
        }

        for index in ToolbarItemIndex.allCases {
            let barItem = controlToolbar.items![index.rawValue]
            predefinedToolbarItemStyle.setup(barItem, state: .normal)
        }
        
    }
    
    var previewView: UIView? {
        return videoVC.previewView
    }
    
    var displayVideoRect: CGRect {
        var rect = videoPlayerSection.bounds
        rect = rect.inset(by: UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0))
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
                    guard let self = self else { return }
                    
                    if self.getPreviewImage() == nil {
                        let cgImage = try! AVAssetImageGenerator(asset: playerItem.asset).copyCGImage(at: CMTime.zero, actualTime: nil)
                        self.setPreviewImage(UIImage(cgImage: cgImage))
                    }
                    
                    self.optionMenu.setPreviewImage(self.getPreviewImage()!)
                    
                    self.cropContainer.superview!.constraints.findById(id: "width").isActive = false
                    self.cropContainer.superview!.constraints.findById(id: "height").isActive = false
                    self.cropContainer.widthAnchor.constraint(equalToConstant: self.displayVideoRect.width).with(identifier: "width").isActive = true
                    self.cropContainer.heightAnchor.constraint(equalToConstant: self.displayVideoRect.height).with(identifier: "height").isActive = true
                    
                    self.cropContainer.setupVideo(frame: self.displayVideoRect)
                    
                    self.videoVC.load(playerItem: playerItem)
                    self.videoVC.videoViewControllerDelegate = self
                    self.setupFiltersSection()
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
    
    private func startSharing(for type: ShareType) {
        guard let asset = videoVC.player?.currentItem?.asset else {
            return
        }
        showLoadingWhenExporting(true)
        let trimPosition = videoController.trimPosition
        let startProgress = trimPosition.leftTrim
        let endProgress = trimPosition.rightTrim
        let speed = Float(playSpeedView.currentSpeedSnapshot)
        let cropArea = cropContainer.cropArea
        let shareManager: ShareManager = ShareManager(asset: asset, startProgress: startProgress, endProgress: endProgress, speed: speed, cropArea: cropArea, filter: videoVC.filter)
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
    
    private func getOptionType(barItem: UIBarButtonItem) -> OptionMenu.MenuType {
        let barItemIndex = controlToolbar.items!.firstIndex(of: barItem)!
        switch barItemIndex {
        case ToolbarItemIndex.playSpeed.rawValue:
            return .playSpeed
        case ToolbarItemIndex.crop.rawValue:
            return .crop
        case ToolbarItemIndex.filters.rawValue:
            return .filters
        default:
            fatalError()
        }
        return .playSpeed
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
    
    @IBAction func onBarItemClicked(_ barItem: UIBarButtonItem) {
        controlToolBarFuntionalItems.filter({$0 != barItem}).forEach { barItem in
            self.predefinedToolbarItemStyle.setup(barItem, state: .normal)
        }
        
        let type = getOptionType(barItem: barItem)
        self.optionMenu.attach(menuType: type)
        var clickedItemInfo: ToolbarItemInfo!
        self.toolbarItemInfos = self.toolbarItemInfos.map {info in
            var info = info
            guard info.barItem == barItem else {
                info.state = .normal
                return info
            }
            if info.state == .normal {
                info.state = .highlight
            } else {
                info.state = .normal
            }
            clickedItemInfo = info
            self.predefinedToolbarItemStyle.setup(barItem, state: info.state)
            return info
        }
        self.stackView.layoutIfNeeded()
        UIView.transition(with: self.videoContainer, duration: 0.3, options: [], animations: {
            clickedItemInfo.state.updateOptionMenuContainer(container: self.optionMenu)
            switch clickedItemInfo.index {
            case .crop:
                self.cropContainer.isEnabled = true
            default:
                self.cropContainer.isEnabled = false
            }

            self.stackView.layoutIfNeeded()
            self.onVideoSectionFrameUpdated()
            self.cropContainer.layoutIfNeeded()
        }, completion: {success in
        })
    }
    
    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
        }
    }
    
    private func enableControlOptions() {
        controlToolBarFuntionalItems.forEach({$0.isEnabled = true})
        shareItem.isEnabled = true
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
        print(trimState)

        videoVC.updateTrim(position: position, state: trimState)
        
        if state == .ended {
            videoController.scrollReason = .other
        }
    }

    /// Change by gallery container scrolling.
    func onTrimChanged(position: VideoTrimPosition, state: VideoTrimState) {
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
    
    func onPreviewSelected(filter: YPFilter) {
        videoVC.setFilter(filter)
    }
    
    func onResetCrop() {
        UIView.transition(with: cropContainer, duration: 0.3, options: .curveEaseInOut, animations: {
            self.cropContainer.resetCrop(videoRect: self.displayVideoRect)
        }, completion: nil)
    }
    
    func onRateChanged(_ rate: Float) {
        videoVC.setRate(rate)
    }
}
