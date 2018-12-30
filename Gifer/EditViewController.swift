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
            #colorLiteral(red: 0.0862745098, green: 0.09019607843, blue: 0.09411764706, alpha: 1).setFill()
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
    
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet var toolbar: UIToolbar!
    
    @IBOutlet weak var optionMenu: UIView!
    @IBOutlet weak var controlToolbar: UIToolbar!
    @IBOutlet weak var videoLoadingIndicator: UIActivityIndicatorView!
    var trimPosition: VideoTrimPosition!
    var videoAsset: PHAsset!
    var loadingDialog: LoadingDialog?
    var predefinedToolbarItemStyle = ToolbarItemStyle()
    var playItemState: ToolbarItemStyle.State = .normal
    
    @IBOutlet weak var stackView: UIStackView!
    override func loadView() {
        super.loadView()
    }
    
    override func viewDidLoad() {
        view.backgroundColor = #colorLiteral(red: 0.0862745098, green: 0.09019607843, blue: 0.09411764706, alpha: 1)
        toolbar.backgroundColor = #colorLiteral(red: 0.0862745098, green: 0.09019607843, blue: 0.09411764706, alpha: 1)

        if isDebug {
            videoAsset = getTestVideo()
        }
        loadVideo()
        setupOptionMenu()
        setupControlToolbar()
    }
    
    var isDebug: Bool {
        get {
            return videoAsset == nil
        }
    }
    
    var playSpeedView: PlaySpeedView!
    fileprivate func addPlaySpeedView() {
        optionMenu.addSubview(playSpeedView)
        NSLayoutConstraint.activate([
            playSpeedView.leadingAnchor.constraint(equalTo: optionMenu.leadingAnchor),
            playSpeedView.trailingAnchor.constraint(equalTo: optionMenu.trailingAnchor),
            playSpeedView.topAnchor.constraint(equalTo: optionMenu.topAnchor),
            playSpeedView.bottomAnchor.constraint(equalTo: optionMenu.bottomAnchor)])
    }
    
    fileprivate func setupOptionMenu() {
        playSpeedView = Bundle.main.loadNibNamed("PlaySpeedView", owner: nil, options: nil)!.first as! PlaySpeedView
        playSpeedView.delegate = self
        self.addPlaySpeedView()
    }
    
    fileprivate func setupControlToolbar() {
        let speedBarItem = toolbar.items![ToolbarItemIndex.speed.rawValue]
        predefinedToolbarItemStyle.setup(speedBarItem, state: .normal)
    }
    
    fileprivate func loadVideo() {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .fastFormat

        DispatchQueue.global().async {
            PHImageManager.default().requestPlayerItem(forVideo: self.videoAsset, options: options) { (playerItem, info) in
                DispatchQueue.main.async {
                    if let playerItem = playerItem {
                        self.videoVC.load(playerItem: playerItem)
                        self.videoVC.videoViewControllerDelegate = self
                        
                        self.videoController.load(playerItem: playerItem)
                        self.videoController.delegate = self
                    }
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
        let startProgress = trimPosition.leftTrim
        let endProgress = trimPosition.rightTrim
        ShareManager(asset: asset, startProgress: startProgress, endProgress: endProgress).share() {
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
        dismiss(animated: true, completion: nil)
    }
}

extension EditViewController: VideoViewControllerDelegate {    
    
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
    
    func onTrimChanged(position: VideoTrimPosition) {
        trimPosition = position
        videoController.updateTrim(position: position)
        videoVC.updateTrim(position: position)        
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

extension EditViewController: PlaySpeedViewDelegate {
    func onRateChanged(_ rate: Float) {
        videoVC.setRate(rate)
    }
    
}
