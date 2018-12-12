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
    
    @IBOutlet weak var controlToolbar: UIToolbar!
    var trimPosition: VideoTrimPosition = VideoTrimPosition(leftTrim: 0, rightTrim: 1)
    var videoAsset: PHAsset!
    
    override func loadView() {
        super.loadView()
    }
    
    
    override func viewDidLoad() {
        view.backgroundColor = UIColor.black

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
        guard let toolbarItems = controlToolbar.items, let playState = videoVC.player?.timeControlStatus else {
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
            controlToolbar.setItems(newToolbarItems, animated: false)
        }
    }
    
    fileprivate func play() {
        videoVC.play()
        videoVC.previewView.isHidden = true
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
private var editVCTransitionShortDuration: TimeInterval = 0.1

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
        
        let image = selectedCell.imageView.image!
        toView.layoutIfNeeded()
        let initialFrame: CGRect = fromView.convert(selectedCell.frame, from: selectedCell.superview!)
        let animateView = AspectView(frame: initialFrame, image: image)
        animateView.imageView.frame = CGRect(origin: CGPoint.zero, size: initialFrame.size)
        var finalImageViewFrame = toVC.view.convert(toVC.videoContainer.frame, from: toVC.videoContainer.superview!)
        finalImageViewFrame.size.height = fromView.safeAreaLayoutGuide.layoutFrame.height - 50 - 44
        
        animateView.layoutIfNeeded()
        toVC.showPreview(false)
        
        toView.alpha = 0
        transitionContext.containerView.addSubview(toView)
        transitionContext.containerView.addSubview(animateView)
        UIView.animate(withDuration: editVCTransitionShortDuration) {
            fromView.alpha = 0
        }
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            toView.alpha = 1
            animateView.frame = finalImageViewFrame
            animateView.makeImageViewFitContainer()
            animateView.layoutIfNeeded()
        }, completion: {completed in
            animateView.removeFromSuperview()
            toVC.showPreview(true)
            toVC.setPreviewImage(image)
            transitionContext.completeTransition(true)
        })        
    }
}


class DismissEditViewControllerAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return editVCTransitionDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let editVC = transitionContext.viewController(forKey: .from) as! EditViewController
        let galleryVC = (transitionContext.viewController(forKey: .to) as! UINavigationController).topViewController as! VideoGalleryViewController
        let editView = transitionContext.view(forKey: .from)!
        let galleryView = transitionContext.view(forKey: .to)!

        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        var initialFrame = editVC.videoContainer.frame
        initialFrame.origin.y = initialFrame.origin.y + statusBarHeight
        let animatedView = AspectView(frame: initialFrame, image: editVC.getPreviewImage()!)
        animatedView.makeImageViewFitContainer()
        let cell = galleryVC.getSelectedCell()!
        let toRect = galleryVC.view.convert(cell.frame, from: cell.superview!)
        
        galleryView.alpha = 0
        UIView.animate(withDuration: editVCTransitionShortDuration, animations: {
            editView.alpha = 0
        })
        
        cell.isHidden = true
        transitionContext.containerView.addSubview(galleryView)
        transitionContext.containerView.addSubview(animatedView)
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            animatedView.frame = toRect
            animatedView.makeImageViewFillContainer()
            galleryView.alpha = 1
        }, completion: {success in
            cell.isHidden = false
            animatedView.removeFromSuperview()
            transitionContext.completeTransition(true)
        })
    }
}
