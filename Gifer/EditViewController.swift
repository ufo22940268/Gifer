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

private enum ToolbarItemIndex: Int {
    case speed = 2
    
}

struct ToolbarItemStyle {
    enum State {
        case normal, highlight

        func animateAdjuster(container: UIView) {
            switch self {
            case .normal:
                container.isHidden = true
            case .highlight:
                container.isHidden = false
            }
        }
    }
    
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
    
    func setup(_ barItem: UIBarButtonItem, state: State) {
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

class EditViewController: UIViewController {
    
    var videoVC: VideoViewController!
    @IBOutlet weak var videoController: VideoController!
    
    var videoContainer: UIView!
    @IBOutlet var toolbar: UIToolbar!
    
    @IBOutlet weak var optionMenu: OptionMenu!
    @IBOutlet weak var controlToolbar: UIToolbar!
    @IBOutlet weak var videoLoadingIndicator: UIActivityIndicatorView!
    var videoAsset: PHAsset!
    var loadingDialog: LoadingDialog?
    var predefinedToolbarItemStyle = ToolbarItemStyle()
    var playItemState: ToolbarItemStyle.State = .normal
    var playSpeedView: PlaySpeedView {
        return optionMenu.playSpeedView
    }

    @IBOutlet weak var cropContainer: CropContainer!
    @IBOutlet weak var stackView: UIStackView!
    override func loadView() {
        super.loadView()
    }
    
    override func viewDidLoad() {
        kdebug_signpost_start(10, 0, 0, 0, 0)
        view.backgroundColor = #colorLiteral(red: 0.0862745098, green: 0.09019607843, blue: 0.09411764706, alpha: 1)
        toolbar.backgroundColor = #colorLiteral(red: 0.0862745098, green: 0.09019607843, blue: 0.09411764706, alpha: 1)

        if isDebug {
            videoAsset = getTestVideo()
        }
        optionMenu.delegate = self
        setupVideoContainer()
        loadVideo()
        setupControlToolbar()
    }
    
    func setupVideoContainer() {
        videoContainer = UIView()
        videoContainer.translatesAutoresizingMaskIntoConstraints = false
        cropContainer.setupCover()
        cropContainer.addContentView(videoContainer)
        let containerWidth = videoContainer.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width)
        containerWidth.identifier = "width"
        containerWidth.isActive = true
        
        let containerHeight = videoContainer.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height)
        containerHeight.identifier = "height"
        containerHeight.isActive = true

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
        let speedBarItem = toolbar.items![ToolbarItemIndex.speed.rawValue]
        predefinedToolbarItemStyle.setup(speedBarItem, state: .normal)
    }
    
    fileprivate func loadVideo() {
        videoVC.showLoading(true)
        
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .fastFormat
        
        PHImageManager.default().requestPlayerItem(forVideo: self.videoAsset, options: options) { [weak self] (playerItem, info) in
            guard let self = self else { return }
            if let playerItem = playerItem {
                self.videoController.load(playerItem: playerItem)
                self.videoController.delegate = self
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.videoVC.load(playerItem: playerItem)
                    self.videoVC.videoViewControllerDelegate = self
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
        let speed = Float(playSpeedView.currentSpeed)
        ShareManager(asset: asset, startProgress: startProgress, endProgress: endProgress, speed: speed).share() {
            DispatchQueue.main.async {
                self.showLoadingWhenExporting(false)
                self.prompt("导出成功")
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
    
    func showLoadingWhenBuffering(_ show: Bool) {
        videoLoadingIndicator.isHidden = !show
    }
    
    fileprivate func play() {
        videoVC.play()
    }
    
    fileprivate func pause() {
        videoVC.pause()
    }
    
    @IBAction func onSpeedBarItemClicked(_ barItem: UIBarButtonItem) {
        UIView.transition(with: self.stackView, duration: 0.3, options: [.showHideTransitionViews], animations: {
            if self.playItemState == .normal {
                self.playItemState = .highlight
            } else {
                self.playItemState = .normal
            }
            self.playItemState.animateAdjuster(container: self.optionMenu)
            self.predefinedToolbarItemStyle.setup(barItem, state: self.playItemState)
        }, completion: nil)
        
    }
    
    @IBAction func onCancel(_ sender: Any) {
        kdebug_signpost_end(10, 0, 0, 0, 0)
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        videoController.dismissed = true
        videoVC.dismissed = true
    }
}

extension EditViewController: VideoViewControllerDelegate {
    
    func onVideoReady(controller: AVPlayerViewController) {
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
        
        cropContainer.widthAnchor.constraint(equalToConstant: controller.videoBounds.width)
        cropContainer.heightAnchor.constraint(equalToConstant: controller.videoBounds.height)
        cropContainer.setupVideo(frame: controller.videoBounds)
    }
    
    func onBuffering(_ inBuffering: Bool) {
        showLoadingWhenBuffering(inBuffering)
    }
    
    func onProgressChanged(progress: CMTime) {
        videoController.updateSliderProgress(progress)
    }
    
    func updatePlaybackStatus(_ status: AVPlayer.TimeControlStatus) {
    }
}

extension EditViewController: VideoControllerDelegate {
    
    func onTrimChanged(position: VideoTrimPosition, state: VideoTrimState) {
        videoController.updateTrim(position: position, state: state)
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
    func onRateChanged(_ rate: Float) {
        videoVC.setRate(rate)
    }
}
