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
    
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet var toolbar: UIToolbar!
    
    var trimPosition: VideoTrimPosition = VideoTrimPosition(leftTrim: 0, rightTrim: 1)
    var videoAsset: PHAsset!
    
    var previewImage: UIImage!
    
    override func loadView() {
        self.navigationController?.toolbar.barTintColor = #colorLiteral(red: 0.262745098, green: 0.262745098, blue: 0.262745098, alpha: 1)
        super.loadView()
    }
    
    
    override func viewDidLoad() {
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
    
    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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

private var editVCTransitionDuration: TimeInterval = 0.5

class ShowEditViewControllerAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    var selectedCell: VideoGalleryCell!
    
    init(selectedCell: VideoGalleryCell) {
        self.selectedCell = selectedCell
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return editVCTransitionDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromView = transitionContext.view(forKey: .from)!
        let toVC = transitionContext.viewController(forKey: .to) as! EditViewController
        let toView = transitionContext.view(forKey: .to)!
        
        let animateImageView = UIImageView(frame: fromView.convert(selectedCell.frame, from: selectedCell.superview!))
        let image = selectedCell.imageView.image
        animateImageView.image = image
        animateImageView.contentMode = .scaleAspectFit
        
        let finalImageViewFrame = toVC.view.convert(toVC.videoContainer.frame, from: toVC.videoContainer.superview!)
        
        transitionContext.containerView.addSubview(animateImageView)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            fromView.alpha = 0
            animateImageView.frame = finalImageViewFrame
        }, completion: {completed in
            animateImageView.removeFromSuperview()
            transitionContext.containerView.addSubview(toView)
            toVC.previewImage = image
            transitionContext.completeTransition(true)
        })
    }
}


class DismissEditViewControllerAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return editVCTransitionDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            transitionContext.viewController(forKey: .to)?.view.alpha = 1.0
            transitionContext.viewController(forKey: .from)?.view.alpha = 0.0
        }, completion: {success in
            transitionContext.completeTransition(true)
        })
    }
}
