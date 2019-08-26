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
    weak var toVC: UIViewController?
    var interactiveTransition = UIPercentDrivenInteractiveTransition()
    
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
        return 0.4
    }
    
    fileprivate func animateTransitionForPresent(in transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: .from)!
        let toVC = transitionContext.viewController(forKey: .to)!
        let toView = transitionContext.view(forKey: .to)!.useAutoLayout()
        let fromView = fromVC.view!
        
        self.toVC = toVC
        
        (toVC as! UINavigationController).navigationBar.shadowImage = UIImage()
        (toVC as! UINavigationController).navigationBar.setBackgroundImage(UIImage(), for: .default)
        overlayContainer.addSubview(toView)
        toView.useSameSizeAsParent()
        NSLayoutConstraint.activate([
            overlayStackView.widthAnchor.constraint(equalToConstant: toView.bounds.width),
            toView.heightAnchor.constraint(equalToConstant: toView.bounds.height)
            ])
        transitionContext.containerView.addSubview(overlayStackView)
        overlayStackView.layoutIfNeeded()
        overlayStackView.transform = CGAffineTransform(translationX: 0, y: transitionContext.containerView.bounds.height)
        fromView.backgroundColor = #colorLiteral(red: 0.06274509804, green: 0.06274509804, blue: 0.06274509804, alpha: 1)
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseOut, animations: {
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
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext),  animations: {
            self.overlayStackView.transform = CGAffineTransform(translationX: 0, y: self.overlayStackView.transform.ty + self.overlayStackView.bounds.height)
            fromVC?.view.transform = .identity
        }) { _ in
            if !transitionContext.transitionWasCancelled {
                self.overlayStackView.removeFromSuperview()
            }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
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
        
        let percent = max(min(sender.translation(in: overlayStackView).y/overlayStackView.bounds.height, 1), 0)
        switch sender.state {
        case .began:
            interactiveTransition.wantsInteractiveStart = true
            toVC.dismiss(animated: true, completion: nil)
        case .changed:
            interactiveTransition.update(percent)
        case .ended:
            if percent > 0.3 {
                interactiveTransition.finish()
            } else {
                interactiveTransition.cancel()
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
            presentedView.frame = presentedView.frame.inset(by: UIEdgeInsets(top: 80, left: 0, bottom: 0, right: 0))
        }        
    }
}

extension OverlayTransitionAnimator: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.location(in: overlayStackView).y < 70
    }
}
