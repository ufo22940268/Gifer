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
import NVActivityIndicatorView

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
    
    enum Source {
        case gallery
        case range
    }
    
    var source = Source.gallery
    
    var shareVC: ShareViewController!
    @IBOutlet weak var videoController: VideoControllerForEdit!
    
    var generator: ItemGenerator? {
        didSet {
            if let generator = generator {
                generator.progressDelegate = self
            }
        }
    }
    
    var videoContainer: UIView!
    @IBOutlet var toolbar: UIToolbar!
    
    var downloadTaskId: PHImageRequestID?
    var playerItemGenerator: ItemGeneratorWithAVAsset?
    
    var optionMenu: OptionMenu!
    var optionMenuTopConstraint: NSLayoutConstraint!
    var optionMenuBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var videoLoadingIndicator: VideoProgressLoadingIndicator!
    var livePhotoAsset: PHAsset!
    var loadingDialog: LoadingDialog?
    @IBOutlet weak var highResButton: UIBarButtonItem!
    
    var speed: Double {
        return Double(playSpeedView.currentSpeed)
    }
    
    var playerItem: ImagePlayerItem?
    var rootFrames: [ImagePlayerFrame]? {
        get {
            return playerItem?.rootFrames
        }
    }
    var rootTimes: [CMTime]? {
        return rootFrames?.map { $0.time }
    }
    
    @IBOutlet weak var cancelItemButton: UIBarButtonItem!
    
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
    
    var previousScale = CGFloat(1)
    
    var mode: Mode {
        if let generator = generator {
            return generator.mode
        } else {
            return .unknown
        }
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
            
            shareBarItem.isEnabled = !isLoadingVideo
            frameBarItem.isEnabled = !isLoadingVideo
            
            controlToolbar.isUserInteractionEnabled = !isLoadingVideo
        }
    }
    
    fileprivate func prepareTestData() {
        //Video PHAsset
        let testAsset = getTestVideo()
        generator = ItemGeneratorWithLibraryVideo(video: testAsset)
        
        //Photos
//        var identitifers = [String]()
//        PHAsset.fetchAssets(with: .image, options: nil).enumerateObjects { (asset, _, _) in
//            identitifers.append(asset.localIdentifier)
//        }
//        generator = ItemGeneratorWithLibraryPhotos(identifiers: identitifers)
    }
    
    override func viewDidLoad() {
        DarkMode.enable(in: self)
        isLoadingVideo = true
        
        view.backgroundColor = UIColor(named: "darkBackgroundColor")
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        isDebug = livePhotoAsset == nil && generator == nil
        if isDebug {
            prepareTestData()
        }
        
        view.tintColor = .mainColor

        if source == .range {            
            navigationItem.leftBarButtonItem = nil
        }
        
        updateSubTitleWhenLoading()
        setupVideoContainer()
        setupControlToolbar()
        setupVideoController()
        
        pinchGesture.delegate = self
        rotationGesture.delegate = self
        
        if let generator = generator {
            load(with: generator)
        }
    }
    
    private func setupVideoController() {
        enableVideoController(false)
    }
    
    private func enableVideoController(_ enable: Bool) {
        videoController.isUserInteractionEnabled = enable
    }
    
    private func updateSubTitleWhenLoading() {
        navigationItem.setTwoLineTitle(lineOne: NSLocalizedString("Edit", comment: "Title in EditViewController"), lineTwo: NSLocalizedString("Loading...", comment: "Loading in navigation title of EditViewController"))
    }

    private func updateSubtitleWithDuration() {
        guard let playerItem = playerItem else { return }
        let fromIndex = playerItem.nearestActiveIndex(time: trimPosition.leftTrim)
        let toIndex = playerItem.nearestActiveIndex(time: trimPosition.rightTrim)
        var duration: CMTime!
        // FIXEME: Change fps will cause the subtitle duration to change.
        if fromIndex == 0 && toIndex == playerItem.activeFrames.count {
            duration = playerItem.duration
        } else {
            duration = CMTime(seconds: playerItem.frameInterval*Double(toIndex - fromIndex), preferredTimescale: 600)
        }
        navigationItem.setTwoLineTitle(lineOne: NSLocalizedString("Edit", comment: ""), lineTwo: String.localizedStringWithFormat(NSLocalizedString("%.1fs/%d frames", comment: "Subtitle metrics in EditViewController"), duration.seconds, toIndex - fromIndex + 1))
    }
    
    func setupVideoContainer() {
        showPlayLoading(true)
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
        controlToolbar.setupAllItems(for: mode, labelCount: 1)
    }
    
    
    func load(with generator: ItemGenerator) {
        isLoadingVideo = true
        videoLoadingIndicator.progress = 0
        generator.run { (playerItem) in
            self.initTrimPosition = VideoTrimPosition(leftTrim: .zero, rightTrim: playerItem.duration)
            self.initPlayerItem(playerItem)
            self.isLoadingVideo = false
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
    
    var videoCache: VideoCache?
    
    fileprivate func initPlayerItem(_ playerItem: ImagePlayerItem) {
        if let previewImage = playerItem.activeFrames.first?.uiImage {
            optionMenu.setPreviewImage(previewImage.resizeImage(60, opaque: false))
            onVideoReady(playerItem: playerItem)
        }
    }
    
    private func convertToRootTime(playItemTime time: CMTime) -> CMTime {
        let frame = playerItem!.nearestActiveFrame(time: time)
        return rootTimes![rootFrames!.firstIndex(of: frame)!]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "frames" || segue.identifier == "addNewPlayerItem" {
            guard var rootFrames = rootFrames, let playerItem = playerItem else { return }
            let vc = (segue.destination as! UINavigationController).topViewController as! FramesViewController
            let left = rootFrames.nearestIndex(time: convertToRootTime(playItemTime: trimPosition.leftTrim))
            let right = rootFrames.nearestIndex(time: convertToRootTime(playItemTime: trimPosition.rightTrim))
            
            if segue.identifier == "addNewPlayerItem" {
                vc.openAddPlayerItemPage = true
            }
            
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
            vc.playerItem = playerItem
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
            texts: editTextOverlay.getTextInfosForExport(imageView: imagePlayerView.imageView),
            adjustFilterAppliers: imagePlayerView.adjustFilterAppliers
        )
    }
    
    func showPromotionDialog() {
        let manager = PromotionManager.default
        if manager.shouldShowDialog() {
            manager.showDialog()
        }
    }
    
    func increasePromotionCount() {
        let manager = PromotionManager.default
        manager.increaseShareTimes()
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
                self.play()
                shareManager.shareToWechat(video: gif, complete: { (success) in
                    self.dismiss(animated: true, completion: nil)
                    self.increasePromotionCount()
                })
            case .system:
                shareManager.shareBySystem(gif: gif, host: self, complete: { (success) in
                    self.dismiss(animated: true, completion: nil)
                    self.play()
                    self.increasePromotionCount()
                })
            case .photo:
                shareManager.saveToPhoto(gif: gif) {success in
                    let alert = UIAlertController(title: nil, message: NSLocalizedString("Export success", comment: ""), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("Go to Library", comment: ""), style: .default, handler: { (_) in
                        UIApplication.shared.open(URL(string:"photos-redirect://")!)
                    }))
                    alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""), style: .default, handler: { (_) in
                        self.dismiss(animated: true, completion: nil)
                        self.onShareDialogDimissed()
                    }))
                    self.present(alert, animated: true, completion: nil)
                    self.increasePromotionCount()
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
        showPromotionDialog()
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
        //Because video loading indicator will hide by itself when progress is reached 100%,
        //so nothing need to do here.
        if show {
            videoLoadingIndicator.isHidden = !show
        }
        
        if let editOverlay = editTextOverlay {
            editOverlay.isHidden = show
        }
        
        if let stickerOverlay = stickerOverlay {
            stickerOverlay.isHidden = show
        }
    }
    
    func play() {
        imagePlayerView.isPaused = false
    }
    
    func pause() {
        imagePlayerView.isPaused = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if playerItem != nil {
            updateSubtitleWithDuration()
        }
        
        imagePlayerView.isPaused = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        loadingDialog?.dismiss(animated: false)

        imagePlayerView.isPaused = true
        
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
        self.playerItem = playerItem
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
        self.videoController.loadInEditVideo(playerItem: playerItem) {
            self.enableVideoController(true)
            self.enableControlOptions()
            self.videoController.layoutIfNeeded()
            self.onTrimChangedByTrimer(trimPosition: self.videoController.trimPosition, state: .initial, side: nil)
            
            //Trim position Updated
            self.defaultGifOptions = self.currentGifOption
            self.updateSubtitleWithDuration()
            
            //Test sticker
//            let image = #imageLiteral(resourceName: "folder-color.png")
//            let component = self.stickerOverlay.addStickerComponent(StickerInfo(image: image))
//            self.videoController.attachView.load(image: component.stickerRender!.renderImage, component: component)
            
//            let component = self.editTextOverlay.addTextComponent(textInfo: EditTextInfo(text: "asdf", fontName: UIFont.familyNames.first!, textColor: .white))
//            self.videoController.attachView.load(text: component.editTextRender!.attachText, component: component)
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
    
    func onAddNewPlayerItem() {
        performSegue(withIdentifier: "addNewPlayerItem", sender: nil)
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
    
    func onAdjustFilterChanged(filterAppliers: [FilterApplier]) {
        imagePlayerView.adjustFilterAppliers = filterAppliers
        imagePlayerView.refreshIfNotPlaying()
    }
    
    func onPromptDismiss(toolbarItem: ControlToolbarItem, commitChange: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
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
        navigationController?.setNavigationBarHidden(true, animated: true)
        optionMenu.isHidden = false
        optionMenu.attach(menuType: toolbarItem)
        optionMenu.layoutIfNeeded()
        UIView.animate(withDuration: Double(UINavigationController.hideShowBarDuration), delay: 0, options: [.curveEaseIn, .transitionCrossDissolve], animations: {
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
        guard var generator = self.generator as? ItemGeneratorFPSAdjustable else { fatalError() }
        FPSFigure.showSelectionDialog(from: self, currentFPS: currentFPS) { (fps) in
            self.controlToolbar.fps = fps
            cell.updateImage(fps.image)
            self.pause()
            self.showPlayLoading(true)
            self.updateSubTitleWhenLoading()
            self.imagePlayerView.useBlankImage()
            
            generator.updateFPS(fps, complete: { (playerItem) in
                self.syncPlayerItemChanges(playerItem)
                self.showPlayLoading(false)
                self.imagePlayerView.restartPlay()
            })
        }
    }
}

extension EditViewController: EditTextDelegate {
    func onAddEditText(info: EditTextInfo) {
        editTextOverlay.addTextComponent(textInfo: info)
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
        videoController.loadGalleryImagesFromPlayerItem()
        imagePlayerView.restartPlay()
        
        controlToolbar.setupAllItems(for: mode, labelCount: playerItem.labels.count)
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

// MARK: Email delegate
extension EditViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: Loading progress delegate
extension EditViewController: GenerateProgressDelegate {
    func onProgress(_ progress: CGFloat) {
        videoLoadingIndicator.progress = progress
    }
}
