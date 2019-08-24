//
//  OverlayTransitionAnimator.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/8/22.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class OverlayTopBar: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: -40, right: 0)).contains(point)
    }
}

class OverlayStackView: UIStackView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let topBar = arrangedSubviews.first, let hitView = topBar.hitTest(topBar.convert(point, from: self), with: event) {
            return hitView
        }
        
        return super.hitTest(point, with: event)
    }
}

class OverlayTransitionAnimator: NSObject, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {
    
    @IBOutlet var overlayContainer: UIView!
    var overlayStackView: UIView!
    @IBOutlet weak var overlayTopBar: UIView!
    weak var toVC: UIViewController?
    var interactiveTransition = UIPercentDrivenInteractiveTransition()
    var triggerDismissByPan = false
    
    override init() {
        super.init()
        overlayStackView = Bundle.main.loadNibNamed("OverlayTopView", owner: self, options: nil)?.first as? UIView
        overlayStackView.useAutoLayout()
        overlayTopBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        overlayTopBar.layer.cornerRadius = 12
        overlayTopBar.clipsToBounds = true
        interactiveTransition.wantsInteractiveStart = true
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveTransition
    }
    

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentController(presentedViewController: presented, presenting: presenting)
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    fileprivate func animateTransitionForPresent(in transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: .from)!
        let toVC = transitionContext.viewController(forKey: .to)!
        let toView = transitionContext.view(forKey: .to)!.useAutoLayout()
        let fromView = fromVC.view!
        
        self.toVC = toVC
        
        overlayContainer.addSubview(toView)
        toView.useSameSizeAsParent()
        NSLayoutConstraint.activate([
            overlayStackView.widthAnchor.constraint(equalToConstant: toView.bounds.width),
            toView.heightAnchor.constraint(equalToConstant: toView.bounds.height)
            ])
        transitionContext.containerView.addSubview(overlayStackView)
        overlayStackView.layoutIfNeeded()
        overlayStackView.transform = CGAffineTransform(translationX: 0, y: transitionContext.containerView.bounds.height)
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseIn, animations: {
            fromView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            fromView.clipsToBounds = true
            fromView.layer.cornerRadius = 16
            self.overlayStackView.transform = CGAffineTransform(translationX: 0, y: transitionContext.containerView.bounds.height - self.overlayStackView.bounds.height)
        }) { (_) in            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    fileprivate func animateTransitionForDismissal(in transitionContext: UIViewControllerContextTransitioning) {
        let galleryVC = transitionContext.viewController(forKey: .from)
        let fromVC = transitionContext.viewController(forKey: .to)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.overlayStackView.transform = CGAffineTransform(translationX: 0, y: self.overlayStackView.transform.ty + self.overlayStackView.bounds.height)
            fromVC?.view.transform = .identity
        }) { _ in
            if !transitionContext.transitionWasCancelled {
                self.overlayStackView.removeFromSuperview()
                transitionContext.completeTransition(true)
            }
        }
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let isPresent = (transitionContext.viewController(forKey: .to) as? UINavigationController)?.topViewController is VideoGalleryViewController
        if isPresent {
            animateTransitionForPresent(in: transitionContext)
        } else {
            animateTransitionForDismissal(in: transitionContext)
        }
    }
    
    @IBAction func onTapToDimiss(_ sender: Any) {
        toVC?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onPanToDismiss(_ sender: UIPanGestureRecognizer) {
        guard let toVC = toVC else { return }
        
        let percent = max(min(sender.translation(in: overlayStackView).y/100, 1), 0)
        switch sender.state {
        case .began:
            triggerDismissByPan = false
            toVC.dismiss(animated: true, completion: nil)
        case .changed:
            interactiveTransition.update(percent)
        case .ended:
            if percent > 1 {
                interactiveTransition.finish()
            }
        case .cancelled:
            interactiveTransition.cancel()
        default:
            break
        }
    }
    
    class PresentController: UIPresentationController {

        override func presentationTransitionWillBegin() {
            guard let presentedView = presentedView else { return }
            presentedView.frame = presentedView.frame.inset(by: UIEdgeInsets(top: 200, left: 0, bottom: 0, right: 0))
        }
        
        override var shouldPresentInFullscreen: Bool {
            return false
        }
    }
}
