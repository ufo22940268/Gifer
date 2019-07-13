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

protocol CropDelegate: class {
    /// - Parameter cropArea: Normalized rect
    func onChange(cropArea: CGRect?)
}

class CropViewController: UIViewController {

    var imagePlayerView: ImagePlayerView {
        return cropPlayerVC.imagePlayerView
    }
    
    @IBOutlet weak var cropMenuView: CropMenuView!
    var cropPlayerVC: CropPlayerViewController!
    var initialCropArea: CGRect?
    
    var playerItem: ImagePlayerItem!
    weak var customDelegate: CropDelegate?
    @IBOutlet weak var toolbar: UIToolbar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if playerItem == nil {
            let asset = getTestVideo()
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { (avAsset, _, _) in
                DispatchQueue.main.async {
                    ImagePlayerItemGenerator(avAsset: avAsset!, trimPosition: VideoTrimPosition(leftTrim: .zero, rightTrim: 1.toTime())).extract(complete: { (playerItem) in
                        self.setup(playerItem: playerItem)
                    })
                }
            }
        } else {
            setup(playerItem: playerItem)
        }
    }
    
    fileprivate func setup(playerItem: ImagePlayerItem) {
        imagePlayerView.load(playerItem: playerItem)
        let videoFrame = AVMakeRect(aspectRatio: playerItem.size, insideRect: self.cropPlayerVC.view.bounds)
        self.cropPlayerVC.videoFrame = videoFrame
        self.cropMenuView.customDelegate = self.cropPlayerVC.cropContainer
    }
    
    override func viewDidLayoutSubviews() {        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "emberCropPlayer" {
            cropPlayerVC = segue.destination as? CropPlayerViewController
            cropPlayerVC.initialCropArea = initialCropArea
        }
    }

    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onDone(_ sender: Any) {
        customDelegate?.onChange(cropArea: cropPlayerVC.cropArea)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onResetCrop(_ sender: Any) {
        cropPlayerVC.cropContainer.resetCropArea()
    }
}
