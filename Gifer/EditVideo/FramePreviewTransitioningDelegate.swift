//
//  FramePreviewTransitioningDelegate.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/30.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AVKit

fileprivate class AnimateView: UIView {
    
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleToFill
        return view
    }()
    
    init(frame: CGRect, image: UIImage) {
        super.init(frame: frame)
        clipsToBounds = true
        imageView.image = image
        addSubview(imageView)
        
        let ratio = max(frame.size.width / image.size.width, frame.size.height / image.size.height)
        let imageViewSize = image.size.applying(CGAffineTransform(scaleX: ratio, y: ratio))
        imageView.frame.origin = CGPoint(x: (bounds.size.width - imageViewSize.width)/2, y: (bounds.size.height - imageViewSize.height)/2)
        imageView.frame.size = imageViewSize
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setImageToFit() {
        imageView.frame = AVMakeRect(aspectRatio: imageView.image!.size, insideRect: bounds)
    }
}

class FramePreviewTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    var cellIndex: Int! = nil
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FramePreviewPresentAnimator(cellIndex: cellIndex, present: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}

class FramePreviewPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    var cellIndex: Int!
    var isPresent: Bool!

    internal init(cellIndex: Int?, present: Bool) {
        self.cellIndex = cellIndex
        isPresent = present
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let previewKey: UITransitionContextViewControllerKey = isPresent ? .to : .from
        let frameKey: UITransitionContextViewControllerKey = isPresent ? .from : .to
        let previewNVC: (UINavigationController) = (transitionContext.viewController(forKey: previewKey) as! UINavigationController)
        let previewVC = previewNVC.topViewController as! FramePreviewViewController
        let previewView = previewVC.view!
        previewView.layoutIfNeeded()
        let frameNVC: (UINavigationController) = (transitionContext.viewController(forKey: frameKey) as! UINavigationController)
        let frameVC = frameNVC.topViewController as! FramesViewController
        
        let cell = frameVC.collectionView.cellForItem(at: IndexPath(row: cellIndex, section: 0)) as! FrameCell
        
        transitionContext.containerView.addSubview(previewView)
        previewView.alpha = 0
        cell.alpha = 0
        
        let animateView = AnimateView(frame: frameNVC.view.convert(cell.bounds, from: cell),  image: cell.image.image!)
        transitionContext.containerView.addSubview(animateView)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 5, options: .curveEaseIn, animations: {
            animateView.frame = previewNVC.view.convert(previewVC.previewView.bounds, from: previewVC.previewView)
            animateView.setImageToFit()
            frameNVC.view.alpha = 0
        }) { (_) in
            animateView.removeFromSuperview()
            previewView.alpha = 1
            cell.alpha = 1
            transitionContext.completeTransition(true)
        }
    }
}


