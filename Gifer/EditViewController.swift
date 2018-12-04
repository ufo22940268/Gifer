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

class EditViewController: UIViewController {
    
    var videoVC: VideoViewController!
    @IBOutlet weak var videoController: VideoController!
    
    @IBOutlet var toolbar: UIToolbar!
    
    var trimPosition: VideoTrimPosition = VideoTrimPosition(leftTrim: 0, rightTrim: 1)
    var videoAsset: PHAsset!
    
    override func loadView() {
        self.navigationController?.toolbar.barTintColor = #colorLiteral(red: 0.262745098, green: 0.262745098, blue: 0.262745098, alpha: 1)
        super.loadView()
    }
    
    
    override func viewDidLoad() {
        setToolbarItems(toolbar.items, animated: false)
        view.backgroundColor = #colorLiteral(red: 0.262745098, green: 0.262745098, blue: 0.262745098, alpha: 1)

        loadVideo()
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
                        self.videoVC.progressDelegator = self
                        
                        self.videoController.load(playerItem: playerItem)
                        self.videoController.slideDelegate = self
                        self.videoController.videoTrim.trimDelegate = self
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "emberVideo" {
            videoVC = segue.destination as? VideoViewController
        }
    }
    
    @IBAction func onPlay(_ sender: UIBarButtonItem) {
        guard let toolbarItems = toolbarItems, let playState = videoVC.player?.timeControlStatus else {
            return
        }

        let itemIndex = toolbarItems.firstIndex(of: sender)!
        var newItem: UIBarButtonItem? = nil
        switch playState {
        case .playing:
            newItem = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(onPlay(_:)))
            pause()
        case .paused:
            newItem = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(onPlay(_:)))
            play()
        case .waitingToPlayAtSpecifiedRate:
            break
        }
        
        if let newItem = newItem {
            var newToolbarItems = toolbarItems
            newToolbarItems[itemIndex] = newItem
            setToolbarItems(newToolbarItems, animated: false)
        }
    }
    
    fileprivate func play() {
        videoVC.play()
    }
    
    fileprivate func pause() {
        videoVC.pause()
    }
}

extension EditViewController: VideoProgressDelegate {
    func onProgressChanged(progress: CGFloat) {
        videoController.updateSliderProgress(progress)
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
    func onSlideVideo(progress: CGFloat) {
        self.videoVC.seek(toProgress: progress)
    }
}
