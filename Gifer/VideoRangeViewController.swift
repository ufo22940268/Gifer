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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupPreview()
        let phAsset = getTestVideo()
        loadPreview(phAsset: phAsset)
    }
    
    private func loadPreview(phAsset: PHAsset) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic
        PHImageManager.default().requestPlayerItem(forVideo: phAsset, options: options) { (playerItem, _) in
            DispatchQueue.main.async {
                //TODO
                self.previewController.videoGravity = .resizeAspectFill
                
                self.previewController.player = AVPlayer(playerItem: playerItem)
            }
        }
    }
    
    
    func setupPreview() {
        previewController = AVPlayerViewController(nibName: nil, bundle: nil)
        previewController.showsPlaybackControls = false
        videoPreviewSection.addSubview(previewController.view)
        NSLayoutConstraint.activate([
            previewController.view.leadingAnchor.constraint(equalTo: videoPreviewSection.leadingAnchor),
            previewController.view.trailingAnchor.constraint(equalTo: videoPreviewSection.trailingAnchor),
            previewController.view.topAnchor.constraint(equalTo: videoPreviewSection.topAnchor),
            previewController.view.bottomAnchor.constraint(equalTo: videoPreviewSection.bottomAnchor)])
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
