//
//  EditStickerTransition.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/20.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class EditStickerTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return Transitioning()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return Transitioning()
    }
    
    class Transitioning: NSObject, UIViewControllerAnimatedTransitioning {
        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return 0.5
        }
        
        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            let present = transitionContext.viewController(forKey: .from) is UINavigationController
            var stickerVC: EditStickerViewController
            var editVC: EditViewController
            if present {
                stickerVC = transitionContext.viewController(forKey: .to) as! EditStickerViewController
                editVC = (transitionContext.viewController(forKey: .from) as! UINavigationController).topViewController as! EditViewController
            } else {
                stickerVC = transitionContext.viewController(forKey: .from) as! EditStickerViewController
                editVC = (transitionContext.viewController(forKey: .to) as! UINavigationController).topViewController as! EditViewController
            }

            if present {
                transitionContext.containerView.addSubview(stickerVC.view)
                stickerVC.view.alpha = 0
                stickerVC.bottomSection.transform = CGAffineTransform(translationX: 0, y: stickerVC.bottomSection.frame.height)
                let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), curve: .easeInOut) {
                    editVC.view.alpha = 0
                    stickerVC.view.alpha = 1
                    stickerVC.bottomSection.transform = .identity
                }
                animator.addCompletion { (_) in
                    transitionContext.completeTransition(true)
                }
                animator.startAnimation()
            } else {
                let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), curve: .easeInOut) {
                    stickerVC.view.alpha = 0
                    stickerVC.bottomSection.transform = CGAffineTransform(translationX: 0, y: stickerVC.bottomSection.frame.height)
                    editVC.view.alpha = 1
                }
                animator.addCompletion { (_) in
                    stickerVC.view.removeFromSuperview()
                    transitionContext.completeTransition(true)
                }
                animator.startAnimation()
            }
        }
    }
}
