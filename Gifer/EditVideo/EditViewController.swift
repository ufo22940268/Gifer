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

struct ToolbarItemInfo {
    var index: ToolbarItem
    var state: ToolbarItemState
    var barItem: UIBarButtonItem
}

class EditViewController: UIViewController {
    
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
    
    var playerItem: ImagePlayerItem! {
        didSet {
            videoController.playerItem = playerItem
        }
    }
    
    var predefinedToolbarItemStyle = ToolbarItemStyle()
    var toolbarItemInfos = [ToolbarItemInfo]()
    
    @IBOutlet weak var videoPlayerSection: VideoPlayerSection!
    var playSpeedView: PlaySpeedView {
        return optionMenu.playSpeedView
    }

    @IBOutlet weak var imagePlayerView: ImagePlayerView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var shareItem: UIBarButtonItem!
    
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
                    item.tintColor = UIColor.white
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
        isDebug = videoAsset == nil && livePhotoAsset == nil
        if isDebug {
            videoAsset = getTestVideo()
            initTrimPosition = VideoTrimPosition(leftTrim: .zero, rightTrim: CMTime(seconds: 2, preferredTimescale: 600))
        }
        
        view.tintColor = .mainColor
        
        setSubTitle("加载中")
        setupVideoContainer()
        setupControlToolbar()
        setupVideoController()
        
        pinchGesture.delegate = self
        rotationGesture.delegate = self
        
        loadAsset()
    }
    
    private func setupVideoController() {
        enableVideoController(false)
    }
    
    private func enableVideoController(_ enable: Bool) {
        videoController.isUserInteractionEnabled = enable
    }
    
    private func enableVideoContainer(_ enable: Bool) {
    }
    
    private func setSubTitle(_ text: String) {
        navigationItem.setTwoLineTitle(lineOne: "编辑", lineTwo: "加载中...")
    }

    private func updateSubTitle() {
        let fromIndex = playerItem.nearestActiveIndex(time: trimPosition.leftTrim)
        let toIndex = playerItem.nearestActiveIndex(time: trimPosition.rightTrim)
        let duration = CMTime(seconds: playerItem.frameInterval*Double(toIndex - fromIndex), preferredTimescale: 600)
        navigationItem.setTwoLineTitle(lineOne: "编辑", lineTwo: String(format: "%.1f秒/%d张", duration.seconds, toIndex - fromIndex + 1))
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
    }
    
    var displayVideoRect: CGRect {
        let rect = videoPlayerSection.bounds
        return AVMakeRect(aspectRatio: videoSize, insideRect: rect)
    }
    
    func loadAsset() {
        getAVAsset { (asset) in
            if let asset = asset {
                self.loadVideo(for: asset)
            }
        }
    }
    
    var videoCache: VideoCache?
    
    private func getAVAsset(completion: @escaping (_ asset: AVAsset?) -> Void) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .mediumQualityFormat
        options.progressHandler = onDownloadVideoProgressChanged
        if let downloadTaskId = downloadTaskId {
            PHImageManager.default().cancelImageRequest(downloadTaskId)
        }
        
        if let videoAsset = videoAsset {
            downloadTaskId = PHImageManager.default().requestAVAsset(forVideo: videoAsset, options: options) { (avAsset, _, _) in
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
                PHAssetResourceManager.default().writeData(for: PHAssetResource.assetResources(for: photo!).first { $0.type == PHAssetResourceType.pairedVideo }!, toFile: url, options: options, completionHandler: { (error) in
                    let asset: AVAsset = AVAsset(url: url)
                    self.initTrimPosition = VideoTrimPosition(leftTrim: .zero, rightTrim: asset.duration)
                    completion(asset)
                })
            }
        }
    }
    
    private func loadVideo(for asset: AVAsset) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .fastFormat
        playerItemGenerator = ImagePlayerItemGenerator(avAsset: asset, trimPosition: initTrimPosition!)
        playerItemGenerator?.extract { playerItem in
            DispatchQueue.main.async { [weak self] in
                guard let this = self else { return }
                this.optionMenu.setPreviewImage(playerItem.activeFrames.first!.uiImage.resizeImage(60, opaque: false))
                this.onVideoReady(playerItem: playerItem)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "frames" {
            let vc = segue.destination as! FramesViewController
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
            texts: editTextOverlay.getTextInfosForExport(imageView: imagePlayerView.imageView)
        )
    }
    
    private func startSharing(for type: ShareType, videoSize: VideoSize, loopCount: LoopCount) {
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
                    self.play()
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
                        self.play()
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    private func onShareDialogDimissed() {
        play()
    }
    
    @IBAction func onShare(_ sender: Any) {
        pause()
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
    
    private func showPlayLoading(_ show: Bool) {
        videoLoadingIndicator.isHidden = !show
    }

    private func showLoading(_ show: Bool, label: String = "") {
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
    
    fileprivate func play() {
        imagePlayerView.paused = false
    }
    
    fileprivate func pause() {
        imagePlayerView.paused = true
    }
    
    @IBAction func onDismiss(_ sender: Any) {
        if defaultGifOptions == nil || defaultGifOptions! == currentGifOption {
            navigationController?.popViewController(animated: true)
            destroy()
        } else {
            ConfirmToDismissDialog().present(by: self) {
                self.navigationController?.popViewController(animated: true)
                self.destroy()
            }
        }
    }
    
    @IBAction func onHighResTapped(_ sender: UIBarButtonItem) {
        var trim = trimPosition
        let delta = min(trim.galleryDuration.seconds, Wechat.maxShareDuration)
        trim.rightTrim = trim.leftTrim + delta.toTime()
        
        UIView.animate(withDuration: 0.3) {
            self.videoController.updateRange(trimPosition: trim)
            self.videoController.layoutIfNeeded()
        }
        
        updateTrim(position: trim, state: .initial, side: .left)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isVideoLoaded {
            updateSubTitle()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        loadingDialog?.dismiss(animated: false)

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
            self.defaultGifOptions = self.currentGifOption
            self.updateSubTitle()
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
        updateTrim(position: trimPosition, state: state, side: playDirection == .forward ? .left : .right)
    }

    //Changed by trimer dragged
    func onTrimChangedByTrimer(trimPosition: VideoTrimPosition, state: VideoTrimState, side: TrimController.Side?) {
        updateTrim(position: trimPosition, state: state, side: side)
    }
    
    /// Update trim info to views except video controller.
    private func updateTrim(position: VideoTrimPosition, state: VideoTrimState, side: TrimController.Side?) {
//        if Wechat.canBeShared(duration: position.galleryDuration) {
//            highResButton.isEnabled = false
//        } else {
//            highResButton.isEnabled = true
//        }
        
        var fixedSide: TrimController.Side!
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
            imagePlayerView.paused = true
        case .finished(_):
            imagePlayerView.paused = false
        default:
            break
        }
        
        updateSubTitle()
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
    
    var allOverlays: [Overlay] {
        return [editTextOverlay, stickerOverlay]
    }
    
    func onPromptDismiss(toolbarItem: ToolbarItem, commitChange: Bool) {
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
    
    func onRateChanged(_ rate: Float) {
        imagePlayerView.rate = rate
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
        let vc = AppStoryboard.Edit.instance.instantiateViewController(withIdentifier: "crop") as! CropViewController
        vc.playerItem = playerItem
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
    
    func onStickerItemClicked() {
        showOptionMenu(for: .sticker)
    }
    
    func onDirectionItemClicked(direction: PlayDirection) {
        imagePlayerView.playDirection = direction
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
        let component = editTextOverlay.addTextComponent(textInfo: info)
        videoController.attachView.load(image: component.editTextRender!.renderImage, component: component)
    }
    
    func onUpdateEditText(info: EditTextInfo, componentId: ComponentId) {
        editTextOverlay.updateTextComponent(textInfo: info, componentId: componentId)
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
                t!.deactiveComponents()
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

extension EditViewController: FramesDelegate {
    func onUpdatePlayerItem(_ playerItem: ImagePlayerItem) {
        self.playerItem = playerItem
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
