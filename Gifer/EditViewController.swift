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
    case play = 2
}

class EditViewController: UIViewController {
    
    var videoVC: VideoViewController!
    @IBOutlet weak var videoController: VideoController!
    
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet var toolbar: UIToolbar!
    
    @IBOutlet weak var controlToolbar: UIToolbar!
    @IBOutlet weak var videoLoadingIndicator: UIActivityIndicatorView!
    var trimPosition: VideoTrimPosition = VideoTrimPosition(leftTrim: 0, rightTrim: 1)
    var videoAsset: PHAsset!
    var loadingDialog: LoadingDialog?
    lazy var playButtons: [AVPlayer.TimeControlStatus: UIBarButtonItem] = {
        return [
            AVPlayer.TimeControlStatus.paused: UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(self.onPlay(_:))),
            AVPlayer.TimeControlStatus.playing: UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(self.onPlay(_:)))
        ]
    }()
    
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
    }
    
    var isDebug: Bool {
        get {
            return videoAsset == nil
        }
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
                        self.videoController.slideDelegate = self
                        self.videoController.videoTrim.trimDelegate = self
                    }
                }
            }
        }
    }
    
    func showPreview(_ show: Bool) {
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
    
    @IBAction func onPlay(_ sender: UIBarButtonItem) {
        guard let playState = videoVC.player?.timeControlStatus else {
            return
        }

        switch playState {
        case .playing:
            pause()
        case .paused:
            play()
        case .waitingToPlayAtSpecifiedRate:
            break
        }
    }
    
    fileprivate func updatePlaybackToolbarItem(by status: AVPlayer.TimeControlStatus) {
        guard let toolbarItems = controlToolbar.items else { return }
        
        let itemIndex = ToolbarItemIndex.play.rawValue
        var newItem: UIBarButtonItem? = nil
        switch status {
        case .playing:
            newItem = playButtons[.paused]
        case .paused:
            newItem = playButtons[.playing]
        case .waitingToPlayAtSpecifiedRate:
            break
        }
        
        if let newItem = newItem {
            var newToolbarItems = toolbarItems
            newToolbarItems[itemIndex] = newItem
            controlToolbar.setItems(newToolbarItems, animated: false)
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
    
    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension EditViewController: VideoViewControllerDelegate {
    
    func onBuffering(_ inBuffering: Bool) {
        showLoadingWhenBuffering(inBuffering)
    }
    
    func onProgressChanged(progress: CGFloat) {
        videoController.updateSliderProgress(progress)
    }
    
    func updatePlaybackStatus(_ status: AVPlayer.TimeControlStatus) {
        updatePlaybackToolbarItem(by: status)
    }
}

extension EditViewController: VideoTrimDelegate {
    
    func onTrimChanged(position: VideoTrimPosition) {
        trimPosition = position
        videoController.updateTrim(position: position)
        videoVC.updateTrim(position: position)        
    }
}

extension EditViewController: SlideVideoProgressDelegate {
    func onSlideVideo(state: SlideState, progress: CGFloat!) {
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
