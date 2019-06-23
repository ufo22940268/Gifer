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
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return EditTextTransitionAnimator()
    }
}

class EditTextTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let inputView = transitionContext.view(forKey: .to)!
        let inputVC = transitionContext.viewController(forKey: .to) as! EditTextViewController
        transitionContext.containerView.addSubview(inputView)
        inputView.alpha = 0
        let editField = inputVC.editField
        editField.transform = CGAffineTransform(translationX: 0, y: 40)
        UIView.transition(with: transitionContext.containerView, duration: transitionDuration(using: transitionContext), options: [], animations: {
            inputView.alpha = 1
            editField.transform = .identity
        }, completion: { success in
            transitionContext.completeTransition(true)
        })
    }
}

