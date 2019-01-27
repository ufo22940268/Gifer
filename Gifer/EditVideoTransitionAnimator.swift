//
//  EditVideoTransitionAnimator.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/12/19.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit
import Photos

private var editVCTransitionDuration: TimeInterval = 0.3
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
        
        animateView.layoutIfNeeded()
    
        toView.alpha = 0
        transitionContext.containerView.addSubview(toView)
        transitionContext.containerView.addSubview(animateView)
        UIView.animate(withDuration: editVCTransitionShortDuration) {
            fromView.alpha = 0
        }
        
        toVC.stackView.layoutIfNeeded()
        toView.layoutIfNeeded()
        let finalImageViewFrame = toVC.videoContainerSection.convert(toVC.videoContainerSection.bounds, to: toVC.view)

        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.2, options: .curveLinear, animations: {
            toView.alpha = 1
            animateView.translatesAutoresizingMaskIntoConstraints = false
            animateView.frame = finalImageViewFrame
            animateView.makeImageViewFitContainer()
            
            animateView.layoutIfNeeded()
        }, completion: {completed in
            toVC.setPreviewImage(image)
            animateView.removeFromSuperview()
            transitionContext.completeTransition(true)
            toVC.loadVideo()
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
        
        let initialFrame = editVC.videoContainer.superview!.convert(editVC.videoContainer.frame, to: editVC.view)
        
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
