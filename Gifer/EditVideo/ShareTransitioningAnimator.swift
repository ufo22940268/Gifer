//
//  ShareTransitioningAnimator.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/16.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class ShareInteractiveAnimator: UIPercentDrivenInteractiveTransition {}


class SharePresentationController: UIPresentationController {
    
    lazy var dimmingView: UIView = {
        let view = UIView().useAutoLayout()
        view.backgroundColor = .black
        view.alpha = 0.7
        return view
    } ()
    
    var dismissHandler: DismissHandler?
    var interactiveAnimator: UIPercentDrivenInteractiveTransition!
    
    init(presentedViewController: UIViewController, presentingViewController: UIViewController?, dismiss: @escaping DismissHandler, interactiveAnimator: UIPercentDrivenInteractiveTransition) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        dismissHandler = dismiss
        self.interactiveAnimator = interactiveAnimator
    }
    
    override func presentationTransitionWillBegin() {
        containerView?.clipsToBounds = true
        containerView?.addSubview(dimmingView)
        dimmingView.useSameSizeAsParent()
        
        guard let presentedView = presentedView, let sourceView = presentingViewController.view else { return }
        presentedView.layer.cornerRadius = 8
        let size = containerView!.bounds.size
        presentedView.frame.origin.y = size.height
        sourceView.layer.cornerRadius = 8
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onTap(sender:)))
        gesture.cancelsTouchesInView = false
        dimmingView.addGestureRecognizer(gesture)
    }
    
    @objc func onTap(sender: UITapGestureRecognizer) {
        if !presentedView!.frame.contains(sender.location(in: containerView)) {
            presentedViewController.dismiss(animated: true, completion: nil)
            dismissHandler?()
        }
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        if (!completed) {
            dimmingView.removeFromSuperview()
        }
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let height = CGFloat(300)
        var rect = CGRect(origin: CGPoint(x: 0, y: containerView!.bounds.height - height), size: CGSize(width: presentingViewController.view.bounds.width, height: height))
        rect = rect.insetBy(dx: 8, dy: 0)
        rect = rect.applying(CGAffineTransform(translationX: 0, y: -presentingViewController.view.safeAreaInsets.bottom))
        return rect
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed {
            dismissHandler?()
        }
    }
}

class ShareTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    var dismissHandler: DismissHandler!
    var interactiveAnimator: ShareInteractiveAnimator!
    
    init(dismiss: @escaping DismissHandler, interator: ShareInteractiveAnimator) {
        self.dismissHandler = dismiss
        self.interactiveAnimator = interator
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveAnimator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ShareDismissAnimator()
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return SharePresentationController(presentedViewController: presented, presentingViewController: presenting, dismiss: dismissHandler, interactiveAnimator: interactiveAnimator)
    }
    
    class ShareDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return 0.25
        }
        
        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            let targetView = transitionContext.view(forKey: .from)!
            UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                targetView.frame.origin.y = transitionContext.containerView.frame.height
            }, completion: {success in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
}



