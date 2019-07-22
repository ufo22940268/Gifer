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

    @IBOutlet weak var imagePlayerView: ImagePlayerView!
    @IBOutlet weak var cropMenuView: CropMenuView!
    var initialCropArea: CGRect?
    
    @IBOutlet weak var cropRootView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var cropContainer: CropContainer!
    var playerItem: ImagePlayerItem!
    weak var customDelegate: CropDelegate?
    @IBOutlet weak var toolbar: UIToolbar!
    
    var videoFrame: CGRect! {
        didSet {
            cropContainer.gridRulerView.setupVideo(frame: videoFrame)
            NSLayoutConstraint.activate([
                cropContainer.imagePlayerView.widthAnchor.constraint(equalToConstant: videoFrame.width),
                cropContainer.imagePlayerView.heightAnchor.constraint(equalToConstant: videoFrame.height)
                ])
        }
    }
    
    var isDidLayoutSubViews = false
    
    var cropArea: CGRect? {
        set(newCropArea) {
            cropContainer.initialCropArea = newCropArea
        }
        
        get {
            return cropContainer.convert(cropContainer.bounds, to: imagePlayerView)
                .applying(CGAffineTransform(scaleX: 1/imagePlayerView.bounds.width, y: 1/imagePlayerView.bounds.height))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if playerItem == nil {
            cropArea = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
        }
        
        cropContainer.scrollView = scrollView
        cropContainer.imagePlayerView = imagePlayerView
        cropContainer.setup()
        
        cropArea = initialCropArea
        
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
    
    override func viewDidLayoutSubviews() {
        if !isDidLayoutSubViews, let videoFrame = videoFrame {
            cropContainer.setupVideo(frame: videoFrame)
        }
        isDidLayoutSubViews = true
    }
    
    fileprivate func setup(playerItem: ImagePlayerItem) {
        imagePlayerView.load(playerItem: playerItem)
        let videoFrame = AVMakeRect(aspectRatio: playerItem.size, insideRect: cropRootView.bounds)
        self.videoFrame = videoFrame
        cropContainer.setupVideo(frame: videoFrame)
        self.cropMenuView.customDelegate = cropContainer
    }
    
    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onDone(_ sender: Any) {
        customDelegate?.onChange(cropArea: cropArea)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onResetCrop(_ sender: Any) {
        cropContainer.resetCropArea()
    }
}
