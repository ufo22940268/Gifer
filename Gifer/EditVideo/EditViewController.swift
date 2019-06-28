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

enum ToolbarItem {
    case playSpeed
    case crop
    case filters
    case font
    case sticker
    case direction(playDirection: PlayDirection)
    
    var viewInfo: (UIImage, String) {
        switch self {
        case .playSpeed:
            return (#imageLiteral(resourceName: "clock-outline.png"), "速度")
        case .crop:
            return (#imageLiteral(resourceName: "crop-outline.png"), "剪裁")
        case .filters:
            return (#imageLiteral(resourceName: "flash-outline.png"), "滤镜")
        case .font:
            return (#imageLiteral(resourceName: "pen-fancy-solid.png"), "文本")
        case .sticker:
            return (#imageLiteral(resourceName: "smile-wink-regular.png"), "贴纸")
        case .direction(let playDirection):
            return playDirection.viewInfo
        }
    }
    
    static var initialAllCases: [ToolbarItem] {
        return [
            .playSpeed, .crop, .filters, .font, .sticker, .direction(playDirection: .forward)
        ]
    }
}

enum PlayDirection {
    case forward, backward
    
    var viewInfo: (UIImage, String) {
        switch self {
        case .forward:
            return (#imageLiteral(resourceName: "arrow-forward-outline.png"), "正向")
        case .backward:
            return (#imageLiteral(resourceName: "arrow-back-outline.png"), "反向")
        }
    }
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

extension UINavigationItem {
    @objc func setTwoLineTitle(lineOne: String, lineTwo: String) {
        let titleParameters = [NSAttributedString.Key.foregroundColor : UIColor.white,
                               NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 17)] as [NSAttributedString.Key : Any]
        let subtitleParameters = [NSAttributedString.Key.foregroundColor : UIColor.white,
                                  NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12)] as [NSAttributedString.Key : Any]
        
        let title:NSMutableAttributedString = NSMutableAttributedString(string: lineOne, attributes: titleParameters)
        let subtitle:NSAttributedString = NSAttributedString(string: lineTwo, attributes: subtitleParameters)
        
        title.append(NSAttributedString(string: "\n"))
        title.append(subtitle)
        
        let size = title.size()
        
        let width = size.width
        let height = CGFloat(44)
        
        let titleLabel = UILabel(frame: CGRect.init(x: 0, y: 0, width: width, height: height))
        titleLabel.attributedText = title
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        titleView = titleLabel
    }
}

class EditViewController: UIViewController {
    
    var videoVC: VideoViewController!
    var shareVC: ShareViewController!
    @IBOutlet weak var videoController: VideoController!
    
    var videoContainer: UIView!
    @IBOutlet var toolbar: UIToolbar!
    
    var downloadTaskId: PHImageRequestID?
    
    var optionMenu: OptionMenu!
    var optionMenuTopConstraint: NSLayoutConstraint!
    var optionMenuBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var videoLoadingIndicator: UIActivityIndicatorView!
    var initialLoadingDialog: LoadingDialog?
    var videoAsset: PHAsset!
    var videoCachedURL: URL?
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
    var previewImage: UIImage!

    var initTrimPosition: VideoTrimPosition?
    var isDebug: Bool!
    var cacheFilePath: URL!
    var customTransitionDelegate = EditTextTransitionDelegate()

    var stickerOverlay: StickerOverlay {
        return cropContainer.stickerOverlay
    }
    
    override func loadView() {
        super.loadView()
    }
    
    lazy var navigationTitleView: UILabel = {
        let label = UILabel()
        label.text = "adsfadf\nadfadf"
        label.textColor = .white
        label.sizeToFit()
        return label
    }()
    
    var isLoadingAsset: Bool = false {
        didSet {
            if isLoadingAsset {
                view.tintAdjustmentMode = .dimmed
                shareItem.tintColor = UIColor.gray
            } else {
                view.tintAdjustmentMode = .automatic
                shareItem.tintColor = .white
            }
        }
    }
    
    override func viewDidLoad() {
        DarkMode.enable(in: self)
        isLoadingAsset = true
        
        view.backgroundColor = UIColor(named: "darkBackgroundColor")
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        isDebug = videoAsset == nil
        if isDebug {
            videoAsset = getTestVideo()
        }
        
        view.tintColor = .mainColor
        
        setSubTitle("加载中")
        setupVideoContainer()
        if previewImage != nil {
            setPreviewImage(previewImage)
        }
        setupControlToolbar()
        setupVideoController()
        
        cacheAndLoadVideo()
        self.view.tintAdjustmentMode = .dimmed
    }
    
    private func setupVideoController() {
        enableVideoController(false)
    }
    
    private func enableVideoController(_ enable: Bool) {
        videoController.isUserInteractionEnabled = enable
    }
    
    private func enableVideoContainer(_ enable: Bool) {
//        videoPlayerSection.isUserInteractionEnabled = enable
    }
    
    private func setSubTitle(_ text: String) {
        navigationItem.setTwoLineTitle(lineOne: "编辑", lineTwo: "加载中...")
    }
    
    private func setSubTitle(duration: CMTime) {
        navigationItem.setTwoLineTitle(lineOne: "编辑", lineTwo: String(format: "%.1f秒", duration.seconds))
    }
    
    func setupVideoContainer() {
        videoContainer = UIView()
        videoContainer.translatesAutoresizingMaskIntoConstraints = false
        cropContainer.setupCover()
        cropContainer.addContentView(videoContainer)
        videoPlayerSection.cropContainer = cropContainer
        cropContainer.customDelegate = self
        
        videoVC = storyboard!.instantiateViewController(withIdentifier: "videoViewController") as? VideoViewController
        addChild(videoVC)
        videoContainer.addSubview(videoVC.view)
        videoContainer.subviews.forEach { view in
            if view != videoVC.view {
                videoContainer.bringSubviewToFront(view)
            }
        }
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
            previewView.heightAnchor.constraint(equalTo: videoPlayerSection.heightAnchor),
            previewView.widthAnchor.constraint(equalTo: videoPlayerSection.widthAnchor),
            previewView.centerXAnchor.constraint(equalTo: videoPlayerSection.centerXAnchor),
            previewView.centerYAnchor.constraint(equalTo: videoPlayerSection.centerYAnchor)
            ])
        previewView.backgroundColor = UIColor.black
        videoVC.previewView = previewView
        
        enableVideoContainer(false)
        
        editTextOverlay.delegate = self
        stickerOverlay.delegate = self
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
    
    func cacheAndLoadVideo() {
        cacheAsset() {url in
            self.loadVideo(for: url)
        }
    }
    
    var videoCache: VideoCache?
    
    private func getAVAsset(completion: @escaping (_ asset: AVAsset?) -> Void) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .fastFormat
        options.progressHandler = onDownloadVideoProgressChanged
        if let downloadTaskId = downloadTaskId {
            PHImageManager.default().cancelImageRequest(downloadTaskId)
        }
        downloadTaskId = PHImageManager.default().requestAVAsset(forVideo: self.videoAsset, options: options) { (avAsset, _, _) in
            completion(avAsset)
        }
    }
    
    var isJumpFromRange: Bool {
        return videoCachedURL != nil
    }
    
    private func cacheAsset(completion: @escaping (_ url: URL) -> Void) {
        if let url = videoCachedURL {
            completion(url)
        } else {
            getAVAsset { (avAsset) in
                guard let avAsset = avAsset else { return }
                self.initTrimPosition = VideoTrimPosition(leftTrim: .zero, rightTrim: avAsset.duration)
                self.videoCache = VideoCache(asset: avAsset, cacheName: "edit")
                self.cacheFilePath = self.videoCache!.tempFilePath
                if self.isJumpFromRange {
                    self.videoCache!.delegate = self
                } else {
                    self.initialLoadingDialog = LoadingDialog(label: "正在加载视频")
                }
                self.videoCache!.parse(trimPosition: self.initTrimPosition, completion: { (url) in
                    self.videoCache?.asset = nil
                    completion(url)
                })
            }
        }
    }
    
    private func loadVideo(for url: URL) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .fastFormat
        let originAsset = AVAsset(url: url)
        let composition = AVMutableComposition()
        composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let videoTrack = composition.tracks(withMediaType: .video).last!
        videoTrack.preferredTransform = originAsset.tracks(withMediaType: .video).first!.preferredTransform
        try! composition.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: originAsset.duration), of: originAsset, at: .zero)
        
        ImagePlayerItemGenerator(avAsset: composition, trimPosition: initTrimPosition!).extract { playerItem in
            DispatchQueue.main.async { [weak self] in
                guard let this = self else { return }
                this.optionMenu.setPreviewImage(playerItem.frames.first!.uiImage.resizeImage(60, opaque: false))
                
                this.cropContainer.superview!.constraints.findById(id: "width").isActive = false
                this.cropContainer.superview!.constraints.findById(id: "height").isActive = false
                this.cropContainer.videoSize = CGSize(width: this.videoAsset.pixelWidth, height: this.videoAsset.pixelHeight)
                this.cropContainer.widthAnchor.constraint(equalToConstant: this.displayVideoRect.width).with(identifier: "width").isActive = true
                this.cropContainer.heightAnchor.constraint(equalToConstant: this.displayVideoRect.height).with(identifier: "height").isActive = true
                
                this.cropContainer.setupVideo(frame: this.displayVideoRect)
                
                //For test
                this.previewView?.isHidden = true
                
                this.videoVC.load(playerItem: playerItem)
                this.videoVC.videoViewControllerDelegate = this
                
                this.onVideoReady(playerItem: playerItem)
            }
        }
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
    
    var videoSize: CGSize {
        return previewImage.size
    }
    
    var currentGifOption: GifGenerator.Options {
        let trimPosition = videoController.trimPosition
        let startProgress = trimPosition.leftTrim
        let endProgress = trimPosition.rightTrim
        let speed = Float(playSpeedView.currentSpeedSnapshot)
        let cropArea = cropContainer.cropArea
        return GifGenerator.Options(
            start: startProgress,
            end: endProgress,
            speed: speed,
            cropArea: cropArea,
            filter: videoVC.filter,
            stickers: stickerOverlay.stickerInfos.map { $0.fixImageFrame(videoSize: videoSize, cropArea: cropArea) },
            direction: videoVC.playDirection,
            exportType: nil,
            texts: editTextOverlay.textInfos.map { $0.fixTextRect(videoSize: videoSize, cropArea: cropArea) }
        )
    }
    
    private func startSharing(for type: ShareType, videoSize: VideoSize, loopCount: LoopCount) {
        guard let cacheFilePath = cacheFilePath else { return  }

        videoVC.pause()
        
        showLoadingWhenExporting(true)
        var options = currentGifOption
        options.exportType = type
        options.videoSize = videoSize
        options.loopCount = loopCount
        let shareManager: ShareManager = ShareManager(asset: AVAsset(url: cacheFilePath), options: options)
        shareManager.share(type: type) { gif in
            self.showLoadingWhenExporting(false)
            
            switch type {
            case .wechat, .wechatSticker:
                shareManager.shareToWechat(video: gif, complete: { (success) in                    
                    self.dismiss(animated: true, completion: nil)
                    self.videoVC.play()
                })
            case .photo:
                shareManager.saveToPhoto(gif: gif) {success in
                    let alert = UIAlertController(title: nil, message: "保存成功", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "前往相册", style: .default, handler: { (_) in
                        UIApplication.shared.open(URL(string:"photos-redirect://")!)
                    }))
                    alert.addAction(UIAlertAction(title: "返回", style: .default, handler: { (_) in
                        self.dismiss(animated: true, completion: nil)
                        self.onShareDialogDimissed()
                        self.videoVC.play()
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    private func onShareDialogDimissed() {
        self.videoVC.play()
    }
    
    @IBAction func onShare(_ sender: Any) {
        videoVC.pause()
        shareVC = ShareViewController(galleryDuration: currentGifOption.duration, shareHandler: startSharing, cancelHandler: onShareDialogDimissed)
        shareVC.present(by: self)
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
    
    @IBAction func onDismiss(_ sender: Any) {
        if defaultGifOptions == nil || defaultGifOptions! == currentGifOption {
            navigationController?.popViewController(animated: true)
        } else {
            ConfirmToDismissDialog().present(by: self) {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(onResume), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onStop), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @objc func onResume() {
        videoVC.play()
    }
    
    @objc func onStop() {
        videoVC.stop()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        videoController.dismissed = true
        videoVC.dismissed = true
        videoVC.destroy()
        
        if let downloadTaskId = downloadTaskId {
            PHImageManager.default().cancelImageRequest(downloadTaskId)
            self.downloadTaskId = nil
        }
        videoCache = nil
    }
}

extension EditViewController: ImagePlayerDelegate {
    
    var videoRect: CGRect {
        return AVMakeRect(aspectRatio: videoVC.videoBounds.size, insideRect: CGRect(origin: CGPoint.zero, size: cropContainer.superview!.frame.size))
    }
    
    var isVideoReady: Bool {
        guard let item = videoVC.player?.currentItem else { return false }
        return item.status == .readyToPlay
    }
    
    var editTextOverlay: EditTextOverlay {
        return cropContainer.editTextOverlay
    }
    
    func mock() {
        let render = TextRender(info: EditTextInfo(text: "asdf", fontName: UIFont.systemFont(ofSize: 10).fontName, textColor: .white))
        let component: OverlayComponent = OverlayComponent(info: OverlayComponent.Info(nRect: CGRect(origin: CGPoint(x: 0.3, y: 0.3), size: CGSize(width: 0.5, height: 0.2))), render: render, clipTrimPosition: videoVC.trimPosition)
        editTextOverlay.addComponent(component: component)
        
        editTextOverlay.active(component: component)
    }
    
    var trimPosition: VideoTrimPosition {
        return videoVC.trimPosition
    }
    
    func onVideoReady(playerItem: ImagePlayerItem) {
//        mock()
//
        isLoadingAsset = false
        loadingDialog?.dismiss()
        loadingDialog = nil
        self.videoController.delegate = self
        cropContainer.onVideoReady(trimPosition: trimPosition)
        self.videoController.load(playerItem: playerItem) {
            self.enableVideoController(true)
            self.enableControlOptions()
            self.videoController.layoutIfNeeded()
            self.onTrimChangedByTrimer(trimPosition: self.videoController.trimPosition, state: .initial, side: nil)

            //Test code
//            self.videoVC.play()
//            self.previewView?.isHidden = true

            self.defaultGifOptions = self.currentGifOption
            self.setSubTitle(duration: self.videoController.galleryDuration)
        }
    }
    
    private func enableControlOptions() {
    }
    
    func onBuffering(_ inBuffering: Bool) {
        videoLoadingIndicator.isHidden = !inBuffering
    }
    
    func onProgressChanged(progress: CMTime) {
        videoController.updateSliderProgress(progress)
        cropContainer.updateOverlayWhenProgressChanged(progress: progress)
    }
    
    func updatePlaybackStatus(_ status: AVPlayer.TimeControlStatus) {
    }
}

extension EditViewController: VideoControllerDelegate {
    func onAttachChanged(component: OverlayComponent, trimPosition: VideoTrimPosition) {
        component.trimPosition = trimPosition
    }
    
    func onTrimChangedByGallerySlider(state: UIGestureRecognizer.State, scrollTime: CMTime, scrollDistance: CGFloat) {
    }
    
    func onTrimChangedByScrollInGallery(trimPosition: VideoTrimPosition, state: VideoTrimState, currentPosition: CMTime) {
        updateTrim(position: trimPosition, state: state, side: videoVC.playDirection == .forward ? .left : .right)
    }

    //Changed by trimer dragged
    func onTrimChangedByTrimer(trimPosition: VideoTrimPosition, state: VideoTrimState, side: TrimController.Side?) {
        updateTrim(position: trimPosition, state: state, side: side)
    }
    
    private func updateTrim(position: VideoTrimPosition, state: VideoTrimState, side: TrimController.Side?) {
        var fixedSide: TrimController.Side!
        if side == nil {
            fixedSide = videoVC.playDirection == .forward ? .left : .right
        } else {
            fixedSide = side
        }
        
        switch state {
        case .finished(_), .started, .initial:
            videoController.stickTo(side: nil)
        default:
            videoController.stickTo(side: fixedSide)
        }
        videoVC.updateTrim(position: position, state: state, side: fixedSide)
        setSubTitle(duration: videoController.galleryDuration)
    }
    
    func onSlideVideo(state: SlideState, progress: CMTime!) {
    }
}

extension EditViewController: OptionMenuDelegate {
    
    func onAdd(sticker: StickerInfo) {
        var component: OverlayComponent
        if let activeComponent = stickerOverlay.activeComponent {
            stickerOverlay.update(sticker: sticker, for: activeComponent)
            component = activeComponent
        } else {
            component = stickerOverlay.addStickerComponent(sticker)
        }
        videoController.attachView.load(image: component.stickerRender!.renderImage, component: component)
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
    
    var allOverlays: [Overlay] {
        return [editTextOverlay, stickerOverlay]
    }
    
    func onPromptDismiss(toolbarItem: ToolbarItem, commitChange: Bool) {
        enableVideoContainer(false)
        switch toolbarItem {
        case .crop:
            if !commitChange {
                cropContainer.resetCropArea()
            }
            self.cropContainer.updateCroppingStatus(.normal)
            break
        case .sticker:
            break
        default:
            break
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.optionMenuBottomConstraint.isActive = false
            self.optionMenuTopConstraint.isActive = true
            self.stackView.setCustomSpacing(0, after: self.videoPlayerSection)
            self.stackView.layoutIfNeeded()
        }) { (_) in
            self.allOverlays.forEach { overlay in
                overlay.isEnabled = true
                self.videoController.onDeactiveComponents()
                overlay.deactiveComponents()
            }
            self.optionMenu.isHidden = true
        }
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
    
    fileprivate func showEditTextViewController(for editText: EditTextInfo = EditTextInfo.initial, componentId: ComponentId? = nil) {
        let vc = EditTextViewController(textInfo: editText)
        vc.delegate = self
        vc.componentId = componentId
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = customTransitionDelegate
        present(vc, animated: true, completion: nil)
    }
    
    func onFontItemClicked() {
        showEditTextViewController()
    }
    
    func onCropItemClicked() {
        enableVideoContainer(true)
        editTextOverlay.isEnabled = false
        stickerOverlay.isEnabled = false
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
        showOptionMenu(for: .sticker)
    }
    
    func onDirectionItemClicked(direction: PlayDirection) {
        videoVC.playDirection = direction
    }
}

extension EditViewController: VideoCacheDelegate {    
    func onParsingProgressChanged(progress: CGFloat) {
    }
    
    func onDownloadVideoProgressChanged(_ progress: Double, e: Error?, p: UnsafeMutablePointer<ObjCBool>, i: [AnyHashable : Any]?) {
    }
}

extension EditViewController: EditTextViewControllerDelegate {
    func onAddEditText(info: EditTextInfo) {
        let component = cropContainer.editTextOverlay.addTextComponent(textInfo: info)
        videoController.attachView.load(image: component.editTextRender!.renderImage, component: component)
    }
    
    func onUpdateEditText(info: EditTextInfo, componentId: ComponentId) {
        cropContainer.editTextOverlay.updateTextComponent(textInfo: info, componentId: componentId)
    }
}

extension EditViewController: OverlayDelegate {
    func onEdit(component: OverlayComponent, id: ComponentId) {
        if let render = component.render as? TextRender {
            showEditTextViewController(for: render.info, componentId: id)
        }
    }
    
    func onActive(overlay: Overlay, component: OverlayComponent) {
        videoController.onActive(component: component)
        let allOverlays = [editTextOverlay, stickerOverlay]
        allOverlays.forEach { t in
            if t != overlay {
                t.deactiveComponents()
            }
        }
        component.superview!.bringSubviewToFront(component)
        overlay.superview!.bringSubviewToFront(overlay)
    }
}

extension EditViewController: CropContainerDelegate {
    func onDeactiveComponents() {
        videoController.onDeactiveComponents()
    }
}
