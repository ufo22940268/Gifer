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

private var editVCTransitionDuration: TimeInterval = 0.3 //0.3
//private var editVCTransitionDuration: TimeInterval = 2 //0.3
private var editVCTransitionShortDuration: TimeInterval = 0.1

class ShowEditViewControllerAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return editVCTransitionDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromView = transitionContext.view(forKey: .from)!
        let fromVC = transitionContext.viewController(forKey: .from)! as! VideoGalleryViewController
        let toVC = transitionContext.viewController(forKey: .to) as! EditViewController
        let toView = transitionContext.view(forKey: .to)!
        
        let selectedCell = fromVC.selectedCell
        
        let image = selectedCell.imageView.image!
        toView.layoutIfNeeded()
        let initialFrame: CGRect = fromVC.navigationController!.view.convert(selectedCell.frame, from: selectedCell.superview!)
        let animateView = AspectView(frame: initialFrame, image: image)
        animateView.imageView.frame = CGRect(origin: CGPoint.zero, size: initialFrame.size)
        
        animateView.layoutIfNeeded()
    
        toView.alpha = 0
        transitionContext.containerView.addSubview(toView)
        transitionContext.containerView.addSubview(animateView)
        UIView.animate(withDuration: editVCTransitionShortDuration) {
            fromView.alpha = 0
            toView.alpha = 1
        }
        
        toView.layoutIfNeeded()
        let finalImageViewFrame = toVC.cropContainer.convert(toVC.cropContainer.bounds, to: transitionContext.containerView)
        toVC.setPreviewImage(image)
        let previewView = toVC.previewView!
        previewView.isHidden = true
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveLinear, animations: {
            animateView.translatesAutoresizingMaskIntoConstraints = false
            animateView.frame = finalImageViewFrame
            animateView.makeImageViewFitContainer()
            animateView.layoutIfNeeded()
        }, completion: {completed in
            animateView.removeFromSuperview()
            toVC.cacheAndLoadVideo()
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
        let galleryVC = transitionContext.viewController(forKey: .to) as! VideoGalleryViewController
        let editView = transitionContext.view(forKey: .from)!
        let galleryView = transitionContext.view(forKey: .to)!
        
        let initialView = editVC.previewView!
        let initialFrame = initialView.superview!.convert(initialView.frame, to: editVC.navigationController!.view)
        
        let animatedView = AspectView(frame: initialFrame, image: editVC.getPreviewImage()!)
        animatedView.makeImageViewFitContainer()
        let cell = galleryVC.getSelectedCell()!
        let toRect = galleryVC.navigationController!.view.convert(cell.frame, from: cell.superview!)
        
        UIView.animate(withDuration: editVCTransitionShortDuration, animations: {
            editView.alpha = 0
            galleryView.alpha = 1
        })
        
        cell.isHidden = true
        transitionContext.containerView.addSubview(galleryView)
        transitionContext.containerView.addSubview(animatedView)
        
        let cropContainer = editVC.cropContainer
        cropContainer?.isHidden = true
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            animatedView.frame = toRect
            animatedView.makeImageViewFillContainer()
        }, completion: {success in
            cell.isHidden = false
            animatedView.removeFromSuperview()
            transitionContext.completeTransition(true)
        })
    }
}
