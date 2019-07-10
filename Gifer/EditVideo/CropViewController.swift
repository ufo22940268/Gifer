//
//  CropViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/9.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import Photos
import AVKit

class CropViewController: UIViewController {

    var imagePlayerView: ImagePlayerView {
        return cropPlayerVC.imagePlayerView
    }
    
    @IBOutlet weak var cropMenuView: CropMenuView!
    var cropPlayerVC: CropPlayerViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if isInitial() {
            let asset = getTestVideo()
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { (avAsset, _, _) in
                DispatchQueue.main.async {
                    ImagePlayerItemGenerator(avAsset: avAsset!, trimPosition: VideoTrimPosition(leftTrim: .zero, rightTrim: 1.toTime())).extract(complete: { (playerItem) in
                        self.setup(playerItem: playerItem)
                        
                        let videoFrame = AVMakeRect(aspectRatio: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), insideRect: self.cropPlayerVC.view.bounds)
                        self.cropPlayerVC.onVideoReady(videoFrame: videoFrame)
                        self.cropMenuView.customDelegate = self.cropPlayerVC.cropContainer
                    })
                }
            }
        }        
    }
    
    func setup(playerItem: ImagePlayerItem) {
        imagePlayerView.load(playerItem: playerItem)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "emberCropPlayer" {
            cropPlayerVC = segue.destination as? CropPlayerViewController
        }
    }
    

    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func onDone(_ sender: Any) {
    }    
}
