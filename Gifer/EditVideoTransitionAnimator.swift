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

private var editVCTransitionDuration: TimeInterval = 0.5 //0.3
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
        
        toView.layoutIfNeeded()
        let finalImageViewFrame = toVC.cropContainer.convert(toVC.cropContainer.bounds, to: transitionContext.containerView)
        toVC.setPreviewImage(image)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.2, options: .curveLinear, animations: {
            toView.alpha = 1
            animateView.translatesAutoresizingMaskIntoConstraints = false
            animateView.frame = finalImageViewFrame
            animateView.makeImageViewFitContainer()
            
            animateView.layoutIfNeeded()
        }, completion: {completed in
            animateView.removeFromSuperview()
            toVC.loadVideo()
            kdebug_signpost(2, 0, 0, 0, 1)
            transitionContext.completeTransition(true)
        })
    }
}


class DismissEditViewControllerAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return editVCTransitionDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        print("transition start")
        kdebug_signpost_start(1, 0, 0, 0, 0)
        let editVC = transitionContext.viewController(forKey: .from) as! EditViewController
        let galleryVC = (transitionContext.viewController(forKey: .to) as! UINavigationController).topViewController as! VideoGalleryViewController
        let editView = transitionContext.view(forKey: .from)!
        let galleryView = transitionContext.view(forKey: .to)!
        
        let initialView = editVC.previewView!
        let initialFrame = initialView.superview!.convert(initialView.frame, to: editVC.view)
        
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
        
//        animatedView.frame = toRect
//        animatedView.makeImageViewFillContainer()
//        galleryView.alpha = 1
//        print("dismiss finished")
//        cell.isHidden = false
//        animatedView.removeFromSuperview()
//        transitionContext.completeTransition(true)
        
        
        UIView.animate(withDuration: 0.3, animations: {
            animatedView.frame = toRect
            animatedView.makeImageViewFillContainer()
            galleryView.alpha = 1
        }, completion: {success in
            kdebug_signpost_end(1, 0, 0, 0, 0)
            print("dismiss finished")
            cell.isHidden = false
            animatedView.removeFromSuperview()
            transitionContext.completeTransition(true)
        })
    }
}
