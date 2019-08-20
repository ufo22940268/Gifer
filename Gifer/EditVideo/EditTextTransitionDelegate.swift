//
//  EditTextTransitionDelegate.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/23.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class EditTextTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    let animator = EditTextTransitionAnimator()
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return animator
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return animator
    }
}

class EditTextTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let isPresent = transitionContext.viewController(forKey: .to) is EditTextViewController
        
        let inputView = transitionContext.view(forKey: isPresent ? .to : .from)!
        let inputVC = transitionContext.viewController(forKey: isPresent ? .to : .from) as! EditTextViewController
//        let editVC = transitionContext.viewController(forKey: isPresent ? .from : .to) as! EditViewController
        let editField = inputVC.editField
        
        if isPresent {
            transitionContext.containerView.addSubview(inputView)
            inputView.alpha = 0
            editField.transform = CGAffineTransform(translationX: 0, y: 40)
            UIView.transition(with: transitionContext.containerView, duration: transitionDuration(using: transitionContext), options: [], animations: {
                inputView.alpha = 1
                editField.transform = .identity
            }, completion: { success in
                transitionContext.completeTransition(true)
            })
        } else {
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseInOut, animations: {
                inputView.alpha = 0
                editField.transform = CGAffineTransform(translationX: 0, y: 40)
            }) { (_) in
                inputView.removeFromSuperview()
                transitionContext.completeTransition(true)
            }
        }
    }
}

