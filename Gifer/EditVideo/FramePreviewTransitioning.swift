//
//  FramePreviewTransitioning.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/8.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class FramePreviewTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    lazy var interactiveAnimator: UIPercentDrivenInteractiveTransition = {
        let transition = UIPercentDrivenInteractiveTransition()
        transition.wantsInteractiveStart = false
        return transition
    }()
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveAnimator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FramePreviewTransitioning()
    }
}

fileprivate class FramePreviewTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            let view = transitionContext.view(forKey: .from)!
            view.transform = CGAffineTransform(translationX: 0, y: view.frame.height)
        }, completion: { success in            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
