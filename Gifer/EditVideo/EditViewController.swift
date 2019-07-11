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
    var playerItemGenerator: ImagePlayerItemGenerator?
    
    var optionMenu: OptionMenu!
    var optionMenuTopConstraint: NSLayoutConstraint!
    var optionMenuBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var videoLoadingIndicator: UIActivityIndicatorView!
    var videoAsset: PHAsset!
    var livePhotoAsset: PHAsset!
    var loadingDialog: LoadingDialog?
    
    var isVideoLoaded: Bool {
        return videoVC.playerItem != nil
    }
    
    var playerItem: ImagePlayerItem! {
        didSet {
            videoVC.imagePlayerView.playerItem = playerItem
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
        let fromIndex = playerItem.nearestActiveIndex(time: videoVC.trimPosition.leftTrim)
        let toIndex = playerItem.nearestActiveIndex(time: videoVC.trimPosition.rightTrim)
        let duration = CMTime(seconds: playerItem.frameInterval*Double(toIndex - fromIndex), preferredTimescale: 600)
        navigationItem.setTwoLineTitle(lineOne: "编辑", lineTwo: String(format: "%.1f秒/%d张", duration.seconds, toIndex - fromIndex + 1))
    }
    
    func setupVideoContainer() {
        videoContainer = UIView()
        videoContainer.translatesAutoresizingMaskIntoConstraints = false
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
                this.videoVC.load(playerItem: playerItem)
                this.videoVC.videoViewControllerDelegate = this
                
                this.onVideoReady(playerItem: playerItem)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "emberVideo" {
            videoVC = segue.destination as? VideoViewController
        } else if segue.identifier == "frames" {
            let vc = segue.destination as! FramesViewController
            vc.playerItem = playerItem
            vc.trimPosition = videoVC.trimPosition
            vc.customDelegate = self
        }
    }
    
    var currentGifOption: GifGenerator.Options {
        let trimPosition = videoController.trimPosition
        let startProgress = trimPosition.leftTrim
        let endProgress = trimPosition.rightTrim
        let speed = Float(playSpeedView.currentSpeedSnapshot)
        
//        fatalError()
        let cropArea: CGRect! = .zero
        return GifGenerator.Options(
            start: startProgress,
            end: endProgress,
            speed: speed,
            cropArea: cropArea,
            filter: videoVC.filter,
            stickers: stickerOverlay.getStickerInfosForExport(videoContainer: imagePlayerView.superview!),
            direction: videoVC.playDirection,
            exportType: nil,
            texts: editTextOverlay.textInfos.map { $0.fixTextRect(videoSize: videoSize, cropArea: cropArea) }
        )
    }
    
    private func startSharing(for type: ShareType, videoSize: VideoSize, loopCount: LoopCount) {
        showLoadingWhenExporting(true)
        var options = currentGifOption
        options.exportType = type
        options.videoSize = videoSize
        options.loopCount = loopCount
        let shareManager: ShareManager = ShareManager(playerItem: videoVC.imagePlayerView.playerItem, options: options)
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
        videoVC.play()
    }
    
    fileprivate func pause() {
        videoVC.pause()
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isVideoLoaded {
            updateSubTitle()
        }
        
        videoVC?.videoViewControllerDelegate = self
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
        loadingDialog?.dismiss(animated: false)
        videoVC.pause()

        if isMovingFromParent {
            destroy()
        }
    }
    
    func destroy() {
        videoController.dismissed = true
        videoVC.dismissed = true
        videoVC.destroy()
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
        self.playerItem = playerItem
        imagePlayerView.load(playerItem: playerItem)
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
        let percent = CGFloat(current - left)/CGFloat(right - left)
        
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
        vc.playerItem = videoVC.playerItem
        vc.customDelegate = self
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
        guard let videoController = videoController else { return true }
        let p = gestureRecognizer.location(in: videoController)
        return !videoController.bounds.contains(p)
    }
}

// MARK: - Crop delegate
extension EditViewController: CropDelegate {
    func onChange(cropArea: CGRect) {
        
    }
}
