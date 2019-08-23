//
//  OverlayTransitionAnimator.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/8/22.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class OverlayTransitionAnimator: NSObject, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {
    
    @IBOutlet var overlayContainer: UIView!
    var overlayStackView: UIView!
    @IBOutlet weak var overlayTopBar: UIView!
    
    override init() {
        super.init()
        overlayStackView = Bundle.main.loadNibNamed("OverlayTopView", owner: self, options: nil)?.first as! UIView
        overlayStackView.useAutoLayout()
        overlayTopBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        overlayTopBar.layer.cornerRadius = 12
        overlayTopBar.clipsToBounds = true
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentController(presentedViewController: presented, presenting: presenting)
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: .from)!
        let toVC = transitionContext.viewController(forKey: .to)!
        let toView = transitionContext.view(forKey: .to)!.useAutoLayout()
        let fromView = fromVC.view!
        
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
        }) { (_) in
            transitionContext.completeTransition(true)
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
