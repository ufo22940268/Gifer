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
import StoreKit
import MessageUI
import MonkeyKing

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

enum ControlToolbarItem {
    case playSpeed
    case crop
    case filters
    case font
    case sticker
    case direction(playDirection: PlayDirection)
    case fps(rate: FPSFigure)
    case adjust
    
    var viewInfo: (UIImage, String) {
        switch self {
        case .playSpeed:
            return (#imageLiteral(resourceName: "clock-outline.png"), NSLocalizedString("Speed", comment: ""))
        case .crop:
            return (#imageLiteral(resourceName: "crop-outline.png"), NSLocalizedString("Crop", comment: ""))
        case .filters:
            return (#imageLiteral(resourceName: "flash-outline.png"), NSLocalizedString("Filter", comment: ""))
        case .font:
            return (#imageLiteral(resourceName: "pen-fancy-solid.png"), NSLocalizedString("Text", comment: ""))
        case .sticker:
            return (#imageLiteral(resourceName: "smile-wink-regular.png"), NSLocalizedString("Sticker", comment: ""))
        case .direction(let playDirection):
            return playDirection.viewInfo
        case .fps(let rate):
            //The fps label size should be 30x30.
            return (rate.image, NSLocalizedString("FPS", comment: ""))
        case .adjust:
            return (#imageLiteral(resourceName: "control-toolbar-adjust.png"), NSLocalizedString("Adjust", comment: ""))
        }
    }
    
    static var initialAllCases: [ControlToolbarItem] {
        return [
            .playSpeed, .crop, .filters, .font, .sticker, .direction(playDirection: .forward),
            .adjust
        ]
    }
}

enum PlayDirection {
    case forward, backward
    
    var viewInfo: (UIImage, String) {
        switch self {
        case .forward:
            return (#imageLiteral(resourceName: "arrow-forward-outline.png"), NSLocalizedString("Forward", comment: ""))
        case .backward:
            return (#imageLiteral(resourceName: "arrow-back-outline.png"), NSLocalizedString("Backward", comment: ""))
        }
    }
}

struct ToolbarItemInfo {
    var index: ControlToolbarItem
    var state: ToolbarItemState
    var barItem: UIBarButtonItem
}

class EditViewController: UIViewController {
    
    enum Mode {
        case photo
        case video
        case livePhoto
        case unknown
    }
    
    var shareVC: ShareViewController!
    @IBOutlet weak var videoController: VideoController!
    
    var videoContainer: UIView!
    @IBOutlet var toolbar: UIToolbar!
    
    var downloadTaskId: PHImageRequestID?
    var playerItemGenerator: ImagePlayerItemGenerator?
    
    var optionMenu: OptionMenu!
    var optionMenuTopConstraint: NSLayoutConstraint!
    var optionMenuBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var videoLoadingIndicator: UIActivityIndicatorView!
    var videoAsset: PHAsset!
    var livePhotoAsset: PHAsset!
    var loadingDialog: LoadingDialog?
    @IBOutlet weak var highResButton: UIBarButtonItem!
    var isVideoLoaded: Bool {
        return playerItem != nil
    }
    
    var speed: Double {
        return Double(playSpeedView.currentSpeed)
    }
    
    var playerItem: ImagePlayerItem?
    var rootFrames: [ImagePlayerFrame]? {
        didSet {
            rootTimes = rootFrames?.map { $0.time }
        }
    }
    var rootTimes: [CMTime]?
    
    @IBOutlet weak var cancelItemButton: UIBarButtonItem!
    /// Use photos to make player item.
    var photoIdentifiers: [String]?
    var makePlayerItemFromPhotosTask: MakePlayerItemFromPhotosTask?
    
    var predefinedToolbarItemStyle = ToolbarItemStyle()
    var toolbarItemInfos = [ToolbarItemInfo]()
    
    @IBOutlet weak var videoPlayerSection: VideoPlayerSection!
    var playSpeedView: PlaySpeedView {
        return optionMenu.playSpeedView
    }

    @IBOutlet weak var imagePlayerView: ImagePlayerView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var shareBarItem: UIBarButtonItem!
    @IBOutlet weak var frameBarItem: UIBarButtonItem!
    
    @IBOutlet var rotationGesture: UIRotationGestureRecognizer!
    @IBOutlet var pinchGesture: UIPinchGestureRecognizer!
    
    @IBOutlet weak var controlToolbar: ControlToolbar!
    var defaultGifOptions: GifGenerator.Options?
    var previewImage: UIImage!
    
    var initTrimPosition: VideoTrimPosition?
    var isDebug: Bool!
    var cacheFilePath: URL!
    var customTransitionDelegate = EditTextTransitionDelegate()

    @IBOutlet weak var stickerOverlay: StickerOverlay!
    @IBOutlet weak var editTextOverlay: EditTextOverlay!
    
    var mode: Mode {
        if videoAsset != nil {
            return .video
        } else if livePhotoAsset != nil {
            return .livePhoto
        } else if photoIdentifiers != nil {
            return .photo
        } else {
            return .unknown
        }
    }
    
    var validPHAsset: PHAsset! {
        return videoAsset ?? livePhotoAsset
    }
    
    var videoSize: CGSize {
        return CGSize(width: validPHAsset.pixelWidth, height: validPHAsset.pixelHeight)
    }
    
    override func loadView() {
        super.loadView()
    }
    
    lazy var navigationTitleView: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.sizeToFit()
        return label
    }()
    
    @IBAction func onTap(_ sender: UITapGestureRecognizer) {
        if let hitComponent = editTextOverlay.getHitComponent(point: sender.location(in: editTextOverlay)) ?? stickerOverlay.getHitComponent(point: sender.location(in: stickerOverlay)) {
            hitComponent.activeByTap()
        } else {
            //Tap to dismiss component
            editTextOverlay.deactiveComponents()
            stickerOverlay.deactiveComponents()
            videoController.onDeactiveComponents()
            
            if let activeItem = optionMenu.activeItem {
                switch optionMenu.activeItem! {
                case .font, .sticker:
                    self.onPromptDismiss(toolbarItem: activeItem, commitChange: false)
                default:
                    break
                }
            }
        }
    }
    
    var previousScale = CGFloat(1)
    
    @IBAction func onPinchToScaleOverlayComponent(_ sender: UIPinchGestureRecognizer) {
        if let activeComponent = stickerOverlay.activeComponent ?? editTextOverlay.activeComponent {
            switch sender.state {
            case .began:
                previousScale = sender.scale
            case .changed:
                activeComponent.scaleBy(sender.scale/previousScale, anchorCenter: true)
                previousScale = sender.scale
            default:
                break
            }
        }
    }
    
    var previousRotation = CGFloat(0)
    
    @IBAction func onRotateOverlayComponent(_ sender: UIRotationGestureRecognizer) {
        if let activeComponent = stickerOverlay.activeComponent ?? editTextOverlay.activeComponent {
            switch sender.state {
            case .began:
                previousRotation = sender.rotation
            case .changed:
                activeComponent.rotateBy(sender.rotation - previousRotation)
                previousRotation = sender.rotation
            default:
                break
            }
        }
    }
    
    @IBAction func onPanToMoveOverlayComponent(_ sender: UIPanGestureRecognizer) {
        if let activeComponent = stickerOverlay.activeComponent ?? editTextOverlay.activeComponent {
            activeComponent.onMove(sender: sender)
        }
    }
    
    var isLoadingVideo: Bool = false {
        didSet {
            if isLoadingVideo {
                view.tintAdjustmentMode = .dimmed
                navigationItem.rightBarButtonItems?.forEach({ (item) in
                    item.tintColor = UIColor.gray
                })
            } else {
                view.tintAdjustmentMode = .automatic
                navigationItem.rightBarButtonItems?.forEach({ (item) in
                    item.tintColor = UIColor.yellowActiveColor
                })
            }
            
            controlToolbar.isUserInteractionEnabled = !isLoadingVideo
        }
    }
    
    override func viewDidLoad() {
        DarkMode.enable(in: self)
        isLoadingVideo = true
        
        view.backgroundColor = UIColor(named: "darkBackgroundColor")
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        isDebug = videoAsset == nil && livePhotoAsset == nil && photoIdentifiers == nil
        if isDebug {
            videoAsset = getTestVideo()
        }
        
        view.tintColor = .mainColor
        
        updateSubTitleWhenLoading()
        setupVideoContainer()
        setupControlToolbar()
        setupVideoController()
        
        pinchGesture.delegate = self
        rotationGesture.delegate = self
        
        if let photoIdentifiers = photoIdentifiers {
            loadPlayerItem(fromPhotos: photoIdentifiers)
        } else {
            load()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.showOptionMenu(for: .adjust)
        }
    }
    
    private func setupVideoController() {
        enableVideoController(false)
    }
    
    private func enableVideoController(_ enable: Bool) {
        videoController.isUserInteractionEnabled = enable
    }
    
    private func enableVideoContainer(_ enable: Bool) {
    }
    
    private func updateSubTitleWhenLoading() {
        navigationItem.setTwoLineTitle(lineOne: NSLocalizedString("Edit", comment: "Title in EditViewController"), lineTwo: NSLocalizedString("Loading...", comment: "Loading in navigation title of EditViewController"))
    }

    private func updateSubtitleWithDuration() {
        guard let playerItem = playerItem else { return }
        let fromIndex = playerItem.nearestActiveIndex(time: trimPosition.leftTrim)
        let toIndex = playerItem.nearestActiveIndex(time: trimPosition.rightTrim)
        let duration = CMTime(seconds: playerItem.frameInterval/speed*Double(toIndex - fromIndex), preferredTimescale: 600)
        navigationItem.setTwoLineTitle(lineOne: NSLocalizedString("Edit", comment: ""), lineTwo: String.localizedStringWithFormat(NSLocalizedString("%.1fs/%d frames", comment: "Subtitle metrics in EditViewController"), duration.seconds, toIndex - fromIndex + 1))
    }
    
    func setupVideoContainer() {
        showPlayLoading(true)
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
        controlToolbar.setupAllItems(for: mode)
    }
    
    var displayVideoRect: CGRect {
        let rect = videoPlayerSection.bounds
        return AVMakeRect(aspectRatio: videoSize, insideRect: rect)
    }
    
    func loadPlayerItem(fromPhotos identifiers: [String]) {
        makePlayerItemFromPhotosTask = MakePlayerItemFromPhotosTask(identifiers: identifiers)
        makePlayerItemFromPhotosTask?.run { playerItem in
            guard let playerItem = playerItem else  { return }
            self.initTrimPosition = VideoTrimPosition(leftTrim: .zero, rightTrim: playerItem.duration)
            self.initPlayerItem(playerItem)
        }
    }
    
    @IBAction func onDismiss(_ sender: Any) {
        var isChanged: Bool!
        if defaultGifOptions == nil {
            isChanged = false
        } else {
            isChanged = !(currentGifOption == defaultGifOptions)
        }
        
        if isChanged {
            let alertController = UIAlertController(title: nil, message: NSLocalizedString("If you go back, your edits will be discarded?", comment: ""), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .destructive, handler: { _ in
                self.dismiss(animated: true, completion: nil)
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func load() {
        loadAVAsset { (asset) in
            if let asset = asset {
                self.makePlayerItem(avAsset: asset) { playerItem in
                    self.initPlayerItem(playerItem)
                }
            }
        }
    }
    
    var videoCache: VideoCache?
    
    private func loadAVAsset(completion: @escaping (_ asset: AVAsset?) -> Void) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .mediumQualityFormat
        if let downloadTaskId = downloadTaskId {
            PHImageManager.default().cancelImageRequest(downloadTaskId)
        }
        
        if let videoAsset = videoAsset {
            downloadTaskId = PHImageManager.default().requestAVAsset(forVideo: videoAsset, options: options) { [weak self] (avAsset, _, _) in
                guard let self = self else { return }
                if self.isDebug {
                    self.initTrimPosition = VideoTrimPosition(leftTrim: .zero, rightTrim: avAsset!.duration)
                }
                completion(avAsset)
            }
        } else if let livePhotoAsset = livePhotoAsset {
            let options = PHLivePhotoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .fastFormat
            PHImageManager.default().requestLivePhoto(for: livePhotoAsset, targetSize: CGSize(width: 700, height: 700), contentMode: .aspectFit, options: options) { (photo, info) in
                if let info = info, info[PHImageErrorKey] != nil {
                    print("error: \(String(describing: info[PHImageErrorKey]))")
                    return
                }
                let url = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("livePhoto.mov")
                try? FileManager.default.removeItem(at: url)
                let options = PHAssetResourceRequestOptions()
                options.isNetworkAccessAllowed = true
                PHAssetResourceManager.default().writeData(for: PHAssetResource.assetResources(for: photo!).first { $0.type == PHAssetResourceType.pairedVideo }!, toFile: url, options: options, completionHandler: { [weak self] (error) in
                    guard let self = self else { return }
                    let asset: AVAsset = AVAsset(url: url)
                    self.initTrimPosition = VideoTrimPosition(leftTrim: .zero, rightTrim: asset.duration)
                    completion(asset)
                })
            }
        }
    }
    
    fileprivate func initPlayerItem(_ playerItem: ImagePlayerItem) {
        optionMenu.setPreviewImage(playerItem.activeFrames.first!.uiImage.resizeImage(60, opaque: false))
        onVideoReady(playerItem: playerItem)
    }
    
    private func makePlayerItem(avAsset: AVAsset, fps: FPSFigure? = nil, complete: @escaping (ImagePlayerItem) -> Void) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .fastFormat
        playerItemGenerator = ImagePlayerItemGenerator(avAsset: avAsset, trimPosition: initTrimPosition!, fps: fps)
        playerItemGenerator?.extract { playerItem in
            DispatchQueue.main.async { [weak self] in
                complete(playerItem)
            }
        }
    }
    
    private func convertToRootTime(playItemTime time: CMTime) -> CMTime {
        let frame = playerItem!.nearestActiveFrame(time: time)
        return rootTimes![rootFrames!.firstIndex(of: frame)!]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "frames" {
            guard var rootFrames = rootFrames, let playerItem = playerItem else { return }
            let vc = (segue.destination as! UINavigationController).topViewController as! FramesViewController
            let left = rootFrames.nearestIndex(time: convertToRootTime(playItemTime: trimPosition.leftTrim))
            let right = rootFrames.nearestIndex(time: convertToRootTime(playItemTime: trimPosition.rightTrim))
            
            for i in 0..<rootFrames.count {
                if i < left || i > right {
                    rootFrames[i].isActive = false
                } else {
                    if let playerFrame = (playerItem.allFrames.first { $0 == rootFrames[i] }) {
                        rootFrames[i].isActive = playerFrame.isActive
                    } else {
                        rootFrames[i].isActive = false
                    }
                }
            }
            vc.setFrames(rootFrames)
            vc.trimPosition = trimPosition
            vc.customDelegate = self
        }
    }
    
    var currentGifOption: GifGenerator.Options {
        let trimPosition = videoController.trimPosition
        let startProgress = trimPosition.leftTrim
        let endProgress = trimPosition.rightTrim
        let speed = Float(playSpeedView.currentSpeedSnapshot)
        
        let cropArea: CGRect = imagePlayerView.cropArea ?? CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
        return GifGenerator.Options(
            start: startProgress,
            end: endProgress,
            speed: speed,
            cropArea: cropArea,
            filter: imagePlayerView.filter,
            stickers: stickerOverlay.getStickerInfosForExport(imageView: imagePlayerView.imageView),
            direction: playDirection,
            exportType: nil,
            texts: editTextOverlay.getTextInfosForExport(imageView: imagePlayerView.imageView)
        )
    }
    
    func promotion() {
        let manager = PromotionManager.default
        manager.increaseShareTimes()
        if manager.shouldShowDialog() {
            manager.showDialog()
        }
    }
    
    private func startSharing(for type: ShareType, videoSize: VideoSize, loopCount: LoopCount) {
        guard let playerItem = playerItem else { return }
        showLoadingWhenExporting(true)
        var options = currentGifOption
        options.exportType = type
        options.videoSize = videoSize
        options.loopCount = loopCount
        let shareManager: ShareManager = ShareManager(playerItem: playerItem, options: options)
        shareManager.share(type: type) { gif in
            self.showLoadingWhenExporting(false)
            
            switch type {
            case .wechat, .wechatSticker:
                shareManager.shareToWechat(video: gif, complete: { (success) in
                    self.dismiss(animated: true, completion: nil)
                    self.promotion()
                    self.play()
                })
            case .photo:
                shareManager.saveToPhoto(gif: gif) {success in
                    let alert = UIAlertController(title: nil, message: NSLocalizedString("Export success", comment: ""), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("Go to Library", comment: ""), style: .default, handler: { (_) in
                        UIApplication.shared.open(URL(string:"photos-redirect://")!)
                    }))
                    alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""), style: .default, handler: { (_) in
                        self.dismiss(animated: true, completion: nil)
                        self.promotion()
                        self.onShareDialogDimissed()
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            case .email:
                shareManager.shareToEmail(gif: gif, from: self)
            }
        }
    }
    
    private func onShareDialogDimissed() {
        play()
    }
    
    @IBAction func onShare(_ sender: Any) {
        pause()
        shareVC = ShareViewController(wechatEnabled: Wechat.canBeShared(playerItem: playerItem!, trimPosition: trimPosition), shareHandler: startSharing, cancelHandler: onShareDialogDimissed)
        shareVC.present(by: self)
    }
    
    private func prompt(_ text: String) {
        let alert = UIAlertController(title: nil, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func showLoadingWhenExporting(_ show: Bool) {
        let label = NSLocalizedString("Exporting...", comment: "")
        guard !isBeingDismissed else { return }
        if (show) {
            if loadingDialog == nil || !(loadingDialog!.isShowing)  {
                loadingDialog = LoadingDialog(label: label)
                loadingDialog!.show(by: self)
            }
        } else {
            loadingDialog?.dismiss()
        }
    }
    
    private func showPlayLoading(_ show: Bool) {
        videoLoadingIndicator.isHidden = !show
    }
    
    func play() {
        imagePlayerView.isPaused = false
    }
    
    func pause() {
        imagePlayerView.isPaused = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isVideoLoaded {
            updateSubtitleWithDuration()
        }
        
        imagePlayerView.isPaused = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        loadingDialog?.dismiss(animated: false)

        imagePlayerView.isPaused = true
        
        makePlayerItemFromPhotosTask?.release()
        if isMovingFromParent {
            destroy()
        }
    }
    
    func destroy() {
        videoController.dismissed = true
        playerItemGenerator?.destroy()
        playerItemGenerator = nil
        
        if let downloadTaskId = downloadTaskId {
            PHImageManager.default().cancelImageRequest(downloadTaskId)
            self.downloadTaskId = nil
        }
        videoCache = nil
        
        imagePlayerView.destroy()
    }
}

extension EditViewController: ImagePlayerDelegate {
    
    var trimPosition: VideoTrimPosition {
        return imagePlayerView.trimPosition
    }
    
    var playDirection: PlayDirection {
        return imagePlayerView.playDirection
    }
    
    func onVideoReady(playerItem: ImagePlayerItem) {
        kdebug_signpost_end(2, 0, 0, 0, 0)
        shareBarItem.isEnabled = true
        frameBarItem.isEnabled = true
        self.playerItem = playerItem
        self.rootFrames = playerItem.allFrames
        self.videoController.playerItem = playerItem
        imagePlayerView.load(playerItem: playerItem)
        imagePlayerView.customDelegate = self
        stickerOverlay.clipTrimPosition = trimPosition
        editTextOverlay.clipTrimPosition = trimPosition
        isLoadingVideo = false
        loadingDialog?.dismiss()
        loadingDialog = nil
        self.videoController.delegate = self
        showPlayLoading(false)        
        self.videoController.load(playerItem: playerItem) {
            self.enableVideoController(true)
            self.enableControlOptions()
            self.videoController.layoutIfNeeded()
            self.onTrimChangedByTrimer(trimPosition: self.videoController.trimPosition, state: .initial, side: nil)
            
            //Trim position Updated
            self.defaultGifOptions = self.currentGifOption
            self.updateSubtitleWithDuration()
        }
    }
    
    
    private func enableControlOptions() {
    }
    
    func onBuffering(_ inBuffering: Bool) {
        videoLoadingIndicator.isHidden = !inBuffering
    }
    
    func onProgressChanged(progress: CMTime) {
        guard let playerItem = playerItem else { return }
        let current = playerItem.nearestActiveIndex(time: progress)
        let left = playerItem.nearestActiveIndex(time: trimPosition.leftTrim)
        let right = playerItem.nearestActiveIndex(time: trimPosition.rightTrim)
        let percent = right == left ? 0 : CGFloat(current - left)/CGFloat(right - left)
        
        videoController.updateSliderProgress(percent: percent)
        allOverlays.forEach { $0.updateWhenProgressChanged(progress: progress) }
    }
}

extension EditViewController: VideoControllerDelegate {
    func onAttachChanged(component: OverlayComponent, trimPosition: VideoTrimPosition) {
        component.trimPosition = trimPosition
    }
    
    func onTrimChangedByGallerySlider(state: UIGestureRecognizer.State, scrollTime: CMTime, scrollDistance: CGFloat) {
    }
    
    func onTrimChangedByScrollInGallery(trimPosition: VideoTrimPosition, state: VideoTrimState, currentPosition: CMTime) {
        updateTrim(position: trimPosition, state: state, side: playDirection == .forward ? .left : .right)
    }

    //Changed by trimer dragged
    func onTrimChangedByTrimer(trimPosition: VideoTrimPosition, state: VideoTrimState, side: ControllerTrim.Side?) {
        updateTrim(position: trimPosition, state: state, side: side)
    }
    
    /// Update trim info to views except video controller.
    private func updateTrim(position: VideoTrimPosition, state: VideoTrimState, side: ControllerTrim.Side?) {
        var fixedSide: ControllerTrim.Side!
        if side == nil {
            fixedSide = playDirection == .forward ? .left : .right
        } else {
            fixedSide = side
        }
        
        switch state {
        case .finished(_), .started, .initial:
            videoController.stickTo(side: nil)
        default:
            videoController.stickTo(side: fixedSide)
        }
        
        if case VideoTrimState.initial = state {} else {
            var toProgress: CMTime!
            if side == .left {
                toProgress = position.leftTrim
            } else {
                toProgress = position.rightTrim
            }
            imagePlayerView.seek(to: toProgress)
        }
        imagePlayerView.trimPosition = position
        
        switch state {
        case .started:
            imagePlayerView.isPaused = true
        case .finished(_):
            imagePlayerView.isPaused = false
        default:
            break
        }
        
        videoController.videoTrim.updateMainColor(duration: playerItem!.calibarateTrimPositionDuration(trimPosition), taptic: true)
        updateSubtitleWithDuration()
    }
    
    func onSlideVideo(state: SlideState, progress: CMTime!) {
    }
}

extension EditViewController: OptionMenuDelegate, EditStickerDelegate {
    
    func onAdd(sticker: StickerInfo) {
        var component: OverlayComponent
        component = stickerOverlay.addStickerComponent(sticker)
        videoController.attachView.load(image: component.stickerRender!.renderImage, component: component)
    }
    
    func onUpdate(sticker: StickerInfo) {
        var component: OverlayComponent
        if let activeComponent = stickerOverlay.activeComponent {
            stickerOverlay.update(sticker: sticker, for: activeComponent)
            component = activeComponent
            videoController.attachView.load(image: component.stickerRender!.renderImage, component: component)
        }
    }
    
    var allOverlays: [Overlay] {
        return [editTextOverlay, stickerOverlay]
    }
    
    func onAdjustFilterChanged(filters: [CIFilter]) {
        imagePlayerView.adjustFilters = filters
        imagePlayerView.refresh()
    }
    
    func onPromptDismiss(toolbarItem: ControlToolbarItem, commitChange: Bool) {
        enableVideoContainer(false)
        switch toolbarItem {
        case .crop:
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
                self.videoController.onDeactiveComponents()
                overlay.deactiveComponents()
            }
            self.optionMenu.isHidden = true
        }
    }
    
    func onPreviewSelected(filter: YPFilter) {
        imagePlayerView.filter = filter
    }
    
    func onSpeedChanged(_ rate: Float) {
        imagePlayerView.rate = rate
        updateSubtitleWithDuration()
    }
}

extension EditViewController: ControlToolbarDelegate {
    
    func showOptionMenu(for toolbarItem: ControlToolbarItem) {
        optionMenu.isHidden = false
        optionMenu.attach(menuType: toolbarItem)
        optionMenu.layoutIfNeeded()
        UIView.animate(withDuration: 0.175, delay: 0, options: [.curveEaseIn, .transitionCrossDissolve], animations: {
            self.optionMenuTopConstraint.isActive = false
            self.optionMenuBottomConstraint.isActive = true
            let heightChanges = self.optionMenu.bounds.height - self.controlToolbar.bounds.height
            self.stackView.setCustomSpacing(heightChanges, after: self.videoPlayerSection)
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
        present(vc, animated: true, completion: {
            self.imagePlayerView.isPaused = true
        })
    }
    
    func onFontItemClicked() {
        showEditTextViewController()
    }
    
    func onAdjustItemClicked() {
        showOptionMenu(for: .adjust)
    }
    
    func onCropItemClicked() {
        guard let playerItem = playerItem else { return }
        let vc = AppStoryboard.Edit.instance.instantiateViewController(withIdentifier: "crop") as! CropViewController
        vc.type = .video(imagePlayerItem: playerItem)
        vc.customDelegate = self
        vc.initialCropArea = imagePlayerView.cropArea
        present(vc, animated: true, completion: nil)
    }
    
    func onFiltersItemClicked() {
        showOptionMenu(for: .filters)
    }
    
    func onPlaySpeedItemClicked() {        
        showOptionMenu(for: .playSpeed)
    }
    
    fileprivate func showEditStickerViewController(stickerInfo: StickerInfo? = nil) {
        let vc = AppStoryboard.Sticker.instance.instantiateViewController(withIdentifier: "stickers") as! EditStickerViewController
        vc.customDelegate = self
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overCurrentContext
        vc.transitioningDelegate = vc.customTransitionDelegate
        vc.stickerInfoForEdit = stickerInfo
        present(vc, animated: true, completion: {
            self.imagePlayerView.isPaused = true
        })
    }
    
    func onDismissed(of viewController: UIViewController) {
        self.imagePlayerView.isPaused = false
    }
    
    func onStickerItemClicked() {
        showEditStickerViewController()
    }
    
    func onDirectionItemClicked(direction: PlayDirection) {
        imagePlayerView.playDirection = direction
    }
    
    func onFPSItemclicked(cell: ControlToolbarItemView, currentFPS: FPSFigure) {
        FPSFigure.showSelectionDialog(from: self, currentFPS: currentFPS) { (fps) in
            self.controlToolbar.fps = fps
            cell.updateImage(fps.image)
            self.pause()
            self.showPlayLoading(true)
            self.updateSubTitleWhenLoading()
            self.imagePlayerView.useBlankImage()
            
            self.loadAVAsset { [weak self] (asset) in
                guard let self = self else { return }
                if let asset = asset {
                    self.makePlayerItem(avAsset: asset, fps: fps) { [weak self] playerItem in
                        guard let self = self else { return }
                        self.syncPlayerItemChanges(playerItem)
                        self.showPlayLoading(false)
                        self.play()
                    }
                }
            }
        }
    }
}

extension EditViewController: EditTextDelegate {
    func onAddEditText(info: EditTextInfo) {
        let component = editTextOverlay.addTextComponent(textInfo: info)
        videoController.attachView.load(image: component.editTextRender!.renderImage, component: component)
    }
    
    func onUpdateEditText(info: EditTextInfo, componentId: ComponentId) {
        editTextOverlay.updateTextComponent(textInfo: info, componentId: componentId)
    }
}

extension EditViewController: OverlayDelegate {
    func onEditComponentTapped(component: OverlayComponent, id: ComponentId) {
        if let render = component.render as? TextRender {
            showEditTextViewController(for: render.info, componentId: id)
        } else if let render = component.render as? StickerRender {
            showEditStickerViewController(stickerInfo: render.info)
        }
    }
    
    func onActiveComponentTapped(overlay: Overlay, component: OverlayComponent) {
        videoController.onActive(component: component)
        let allOverlays = [editTextOverlay, stickerOverlay]
        allOverlays.forEach { t in
            if t != overlay {
                t!.deactiveComponents()
            }
        }
        component.superview!.bringSubviewToFront(component)
        overlay.superview!.bringSubviewToFront(overlay)
    }
    
    func onDeleteComponentTapped(component: OverlayComponent) {
        videoController.onDeactiveComponents()
    }
}

extension EditViewController: CropContainerDelegate {
    func onDeactiveComponents() {
        videoController.onDeactiveComponents()
    }
}

extension EditViewController: FramesDelegate {
    
    func syncPlayerItemChanges(_ playerItem: ImagePlayerItem) {
        self.playerItem = playerItem
        videoController.playerItem = playerItem
        videoController.updatePlayerItem(playerItem)
        imagePlayerView.updatePlayerItem(playerItem)
        updateTrim(position: playerItem.allRangeTrimPosition, state: .initial, side: .left)
        videoController.updateRange(trimPosition: playerItem.allRangeTrimPosition)
        
        videoController.attachView.resetTrim()
        stickerOverlay.clipTrimPosition = playerItem.allRangeTrimPosition
        editTextOverlay.clipTrimPosition = playerItem.allRangeTrimPosition
        
        imagePlayerView.currentTime = .zero
    }
    
    func onUpdateFrames(_ frames: [ImagePlayerFrame]) {
        guard let playerItem = playerItem else { return }
        let activeFrames = frames.filter { $0.isActive }
        playerItem.allFrames = activeFrames
        playerItem.resetAllFrameTimes()
        playerItem.duration = playerItem.allFrames.last!.time
        syncPlayerItemChanges(playerItem)
    }
}

extension EditViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if navigationController?.interactivePopGestureRecognizer == gestureRecognizer {
            guard let videoController = videoController else { return true }
            let p = gestureRecognizer.location(in: videoController)
            return !videoController.bounds.contains(p)
        } else {
            return true
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if [gestureRecognizer, otherGestureRecognizer].allSatisfy({ $0 == self.pinchGesture || $0 == self.rotationGesture }) {
            return true
        } else {
            return false
        }
    }
}

// MARK: - Crop delegate
extension EditViewController: CropDelegate {
    func onChange(cropArea: CGRect?) {
        imagePlayerView.cropArea = cropArea
    }
}

extension EditViewController: UINavigationBarDelegate {
    
    
    func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        var isChanged: Bool!
        if defaultGifOptions == nil {
            isChanged = false
        } else {
            isChanged = !(currentGifOption == defaultGifOptions)
        }
        
        if isChanged {
            let alertController = UIAlertController(title: nil, message: NSLocalizedString("If you go back, your edits will be discarded?", comment: ""), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .destructive, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
        return !isChanged
    }
}

extension EditViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
