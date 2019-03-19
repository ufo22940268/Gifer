//
//  VideoRangeViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/19.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit
import Photos

class VideoRangeViewController: UIViewController {
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var videoPreviewSection: UIView!
    var previewController: AVPlayerViewController!
    var player: AVPlayer {
        return previewController.player!
    }
    var currentItem: AVPlayerItem {
        return player.currentItem!
    }
    @IBOutlet weak var videoController: VideoController!
    var previewAsset: PHAsset!
    var timeObserverToken: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupPreview()
        previewAsset = getTestVideo()
        loadPreview(phAsset: previewAsset)
    }
    
    private func loadPreview(phAsset: PHAsset) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic
        PHImageManager.default().requestPlayerItem(forVideo: phAsset, options: options) { (playerItem, _) in
            guard let playerItem = playerItem else { return }
            DispatchQueue.main.async {
                //TODO
                self.previewController.player = AVPlayer(playerItem: playerItem)
                self.previewController.player?.play()
                self.previewController.view.translatesAutoresizingMaskIntoConstraints = false
                self.videoController.load(playerItem: playerItem, completion: {
                    
                })
                self.registerObservers()
            }
        }
    }
    
    private func registerObservers() {
        self.previewController.player!.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: nil)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
                                                            queue: .main) {
                                                                [weak self] time in
                                                                self?.observePlayProgress(progress: time)
        }
    }
    
    private func observePlayProgress(progress: CMTime) {
        if case AVPlayer.Status.readyToPlay = player.status {
            videoController.updateSliderProgress(progress)
        }
    }
    
    private func unregisterObservers() {
        self.removeObserver(self.previewController.player!, forKeyPath: #keyPath(AVPlayerItem.status))
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.status) {
            let player = object as! AVPlayer
            if case AVPlayer.Status.readyToPlay = player.status {
                let targetSize = AVMakeRect(aspectRatio: CGSize(width: previewAsset.pixelWidth, height: previewAsset.pixelHeight), insideRect: videoPreviewSection.bounds).size
                previewController.view.constraints.findById(id: "width").constant = targetSize.width
                previewController.view.constraints.findById(id: "height").constant = targetSize.height
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        unregisterObservers()
    }
    
    
    func setupPreview() {
        previewController = AVPlayerViewController(nibName: nil, bundle: nil)
        previewController.showsPlaybackControls = false
        videoPreviewSection.addSubview(previewController.view)
        videoPreviewSection.backgroundColor = .black
        NSLayoutConstraint.activate([
            previewController.view.widthAnchor.constraint(equalToConstant: videoPreviewSection.bounds.width).with(identifier: "width"),
            previewController.view.heightAnchor.constraint(equalToConstant: videoPreviewSection.bounds.height).with(identifier: "height"),
            previewController.view.centerXAnchor.constraint(equalTo: videoPreviewSection.centerXAnchor),
            previewController.view.centerYAnchor.constraint(equalTo: videoPreviewSection.centerYAnchor)
        ])
        didMove(toParent: previewController)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
