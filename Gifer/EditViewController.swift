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
}

struct ToolbarItemInfo {
    var index: ToolbarItemIndex
    var state: ToolbarItemState
    var barItem: UIBarButtonItem
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
    
    @IBOutlet weak var videoContainerSection: VideoPlayerSection!
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
        kdebug_signpost_start(10, 0, 0, 0, 0)
        view.backgroundColor = #colorLiteral(red: 0.0862745098, green: 0.09019607843, blue: 0.09411764706, alpha: 1)
        toolbar.backgroundColor = #colorLiteral(red: 0.0862745098, green: 0.09019607843, blue: 0.09411764706, alpha: 1)

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
        
        videoContainerSection.cropContainer = cropContainer
        
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
    
    func loadVideo() {
        videoLoadingIndicator.isHidden = false
        
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .fastFormat
        
        PHImageManager.default().requestPlayerItem(forVideo: self.videoAsset, options: options) { [weak self] (playerItem, info) in
            guard let self = self else { return }
            if let playerItem = playerItem {

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.videoVC.load(playerItem: playerItem)
                    self.videoVC.videoViewControllerDelegate = self
                    
                    self.videoController.delegate = self
                    self.videoController.load(playerItem: playerItem)

                    self.videoVC.play()
                }
            }
        }
    }
    
    
    func getPreviewImage() -> UIImage? {
        return videoVC.previewView.image
    }
    
    func setPreviewImage(_ image: UIImage)  {
        videoVC.setPreviewImage(image)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "emberVideo" {
            videoVC = segue.destination as? VideoViewController
        }
    }
    
    @IBAction func onShare(_ sender: Any) {
        guard let asset = videoVC.player?.currentItem?.asset else {
            return
        }
        showLoadingWhenExporting(true)
        videoVC.pause()
        let trimPosition = videoController.trimPosition
        let startProgress = trimPosition.leftTrim
        let endProgress = trimPosition.rightTrim
        let speed = Float(playSpeedView.currentSpeedSnapshot)
        let cropArea = cropContainer.cropArea
        ShareManager(asset: asset, startProgress: startProgress, endProgress: endProgress, speed: speed, cropArea: cropArea).share( exportComplete: { (exportSuccess) in
            DispatchQueue.main.async {
                self.showLoadingWhenExporting(false)
            }
        }) { (shareSuccess) in
            DispatchQueue.main.async {                
                self.dismiss(animated: true, completion: nil)
            }
        }
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
        UIView.transition(with: self.videoContainer, duration: 0.3, options: [.transitionCrossDissolve], animations: {
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
    
    func onVideoReady(controller: AVPlayerViewController) {
        
        videoVC.previewView.isHidden = true
        enableControlOptions()
        
        ["width", "height"].forEach { (id) in
            cropContainer.superview!.constraints.filter({ (ns) -> Bool in
                ns.identifier == id
            }).forEach({ (ns) in
                ns.isActive = false
            })
            
            videoContainer.constraints.filter({ (ns) -> Bool in
                ns.identifier == id
            }).forEach({ (ns) in
                ns.isActive = false
            })
        }
        
        let width = cropContainer.widthAnchor.constraint(equalToConstant: videoRect.width)
        width.identifier = "width"
        width.isActive = true
        let height = cropContainer.heightAnchor.constraint(equalToConstant: videoRect.height - 32)
        height.identifier = "height"
        height.isActive = true
        
        cropContainer.setupVideo(frame: videoRect)
        onTrimChanged(position: videoController.trimPosition, state: .initial)
    }
    
    private func enableControlOptions() {
        controlToolBarFuntionalItems.forEach({$0.isEnabled = true})
        shareItem.isEnabled = true
    }
    
    func onBuffering(_ inBuffering: Bool) {
        videoLoadingIndicator.isHidden = !inBuffering
    }
    
    func onProgressChanged(progress: CMTime) {
        videoController.updateSliderProgress(progress)
    }
    
    func updatePlaybackStatus(_ status: AVPlayer.TimeControlStatus) {
    }
}

extension EditViewController: VideoControllerDelegate {
    
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
    
    func onResetCrop() {
        UIView.transition(with: cropContainer, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.cropContainer.resetCrop()
        }, completion: nil)
    }
    
    func onRateChanged(_ rate: Float) {
        videoVC.setRate(rate)
    }
}
