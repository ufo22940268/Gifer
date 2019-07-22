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

protocol Croppable {
    var contentSize: CGSize { get }
}

extension UIImage: Croppable {
    var contentSize: CGSize {
        return size
    }
}

extension ImagePlayerItem: Croppable {
    var contentSize: CGSize {
        return size
    }
}

class CropViewController: UIViewController {
    
    enum `Type` {
        case video(imagePlayerItem: ImagePlayerItem)
        case image(image: UIImage)
    }

    @IBOutlet weak var imagePlayerView: ImagePlayerView!
    @IBOutlet weak var cropMenuView: CropMenuView!
    var initialCropArea: CGRect?
    
    @IBOutlet weak var cropRootView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var cropContainer: CropContainer!
    var cropEntity: Croppable?
    weak var customDelegate: CropDelegate?
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var vcContainer: UIView!
    
    var type: Type!
    
    var videoFrame: CGRect! {
        didSet {
            cropContainer.gridRulerView.setupVideo(frame: videoFrame)
        }
    }
    
    var isCropContainerInitialized = false
    
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
        
        if cropEntity == nil {
            cropArea = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
        }
        
        cropContainer.scrollView = scrollView
        cropContainer.setup()
        
        cropArea = initialCropArea
        
        if cropEntity == nil {
            let asset = getTestVideo()
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { (avAsset, _, _) in
                DispatchQueue.main.async {
                    ImagePlayerItemGenerator(avAsset: avAsset!, trimPosition: VideoTrimPosition(leftTrim: .zero, rightTrim: 1.toTime())).extract(complete: { (playerItem) in
                        self.type = .video(imagePlayerItem: playerItem)
                        self.onResourceReady()
                    })
                }
            }
        } else {
//            setup(playerItem: cropEntity)
        }
    }
    
    func onResourceReady() {
        switch self.type! {
        case let .video(playerItem):
            cropEntity = playerItem
            let cropVideoVC = AppStoryboard.Edit.instance.instantiateViewController(withIdentifier: "cropVideo") as! CropVideoViewController
            addChild(cropVideoVC)
            cropVideoVC.view.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(cropVideoVC.view)
            cropVideoVC.view.useSameSizeAsParent()
            cropVideoVC.didMove(toParent: self)
            cropVideoVC.load(playerItem: playerItem)
            cropContainer.contentView = cropVideoVC.contentView
            layoutCropContainer()
        case let .image(image):
            break
        }
        
        self.cropMenuView.customDelegate = cropContainer
    }
    
    fileprivate func layoutCropContainer() {
        guard let cropEntity = cropEntity else { return }
        self.videoFrame = AVMakeRect(aspectRatio: cropEntity.contentSize, insideRect: cropRootView.bounds)
        cropContainer.setupVideo(frame: videoFrame)
    }
    
    override func viewDidLayoutSubviews() {
        layoutCropContainer()
    }
    
//    fileprivate func setup(playerItem: Croppable) {
//        imagePlayerView.load(playerItem: playerItem)
//        updateVideoFrame()
//        self.cropMenuView.customDelegate = cropContainer
//    }
    
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
