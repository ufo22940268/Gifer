//
//  OverlayTransitionAnimator.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/8/22.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class OverlayTransitionAnimator: NSObject, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {
    
    weak var toVC: UIViewController?
    var interactiveTransition = UIPercentDrivenInteractiveTransition()

    override init() {
        super.init()
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
        let overlayView = transitionContext.view(forKey: .to)!.useAutoLayout()
        let fromView = fromVC.view!
        
        self.toVC = toVC
        
        (toVC as! UINavigationController).navigationBar.shadowImage = UIImage()
        (toVC as! UINavigationController).navigationBar.setBackgroundImage(UIImage(), for: .default)
        transitionContext.containerView.addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: transitionContext.containerView.topAnchor),
            overlayView.centerXAnchor.constraint(equalTo: transitionContext.containerView.centerXAnchor),
            overlayView.heightAnchor.constraint(equalToConstant: transitionContext.containerView.bounds.height - 80),
            ])
        overlayView.layoutIfNeeded()
        let panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onPanToDismiss(_:)))
        overlayView.addGestureRecognizer(panGesture)
        panGesture.delegate = self
        overlayView.transform = CGAffineTransform(translationX: 0, y: transitionContext.containerView.bounds.height)
        fromView.backgroundColor = #colorLiteral(red: 0.06274509804, green: 0.06274509804, blue: 0.06274509804, alpha: 1)
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseOut, animations: {
            fromView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            fromView.clipsToBounds = true
            fromView.layer.cornerRadius = 16
            overlayView.transform = CGAffineTransform(translationX: 0, y: transitionContext.containerView.bounds.height - overlayView.bounds.height)
        }) { (_) in            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    fileprivate func animateTransitionForDismissal(in transitionContext: UIViewControllerContextTransitioning) {
        let galleryVC = transitionContext.viewController(forKey: .from)
        let fromVC = transitionContext.viewController(forKey: .to)
        let overlayView = transitionContext.view(forKey: .from)!
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext),  animations: {
            overlayView.transform = CGAffineTransform(translationX: 0, y: overlayView.transform.ty + overlayView.bounds.height)
            fromVC?.view.transform = .identity
        }) { _ in
            if !transitionContext.transitionWasCancelled {
                overlayView.removeFromSuperview()
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
    
    @IBAction func onPanToDismiss(_ sender: UIPanGestureRecognizer) {
        guard let toVC = toVC else { return }

        let overlayStackView = sender.view!
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
        
        @IBOutlet var overlayContainer: UIView!
        var overlayStackView: UIView!
        @IBOutlet weak var overlayTopBar: UIView!
        
        lazy var dimmingView: UIView = {
            let view = UIView().useAutoLayout()
            view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            return view
        }()

        override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
            super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
            overlayStackView = Bundle.main.loadNibNamed("OverlayTopView", owner: self, options: nil)?.first as? UIView
            overlayStackView.useAutoLayout()
            overlayTopBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            overlayTopBar.layer.cornerRadius = 12
            overlayTopBar.clipsToBounds = true
            
            overlayContainer.addSubview(super.presentedViewController.view)
            super.presentedViewController.view.setContentHuggingPriority(.defaultLow, for: .vertical)
            super.presentedViewController.view.useAutoLayout()
            super.presentedViewController.view.useSameSizeAsParent()
            NSLayoutConstraint.activate([
                overlayStackView.widthAnchor.constraint(equalToConstant: super.presentedViewController.view.bounds.width)
                ])
        }
        
        override var presentedView: UIView? {
            return overlayStackView
        }

        override func presentationTransitionWillBegin() {
            guard let presentedView = presentedView else { return }
            presentedView.frame = presentedView.frame.inset(by: UIEdgeInsets(top: 80, left: 0, bottom: 0, right: 0))
            containerView?.insertSubview(dimmingView, at: 0)
            dimmingView.useSameSizeAsParent()
            dimmingView.alpha = 0
            presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (context) in
                
                //No animations. Can't figure out why.
//                self.dimmingView.alpha = 1
            }, completion: nil)
        }
        
        override func presentationTransitionDidEnd(_ completed: Bool) {
            if !completed {
                dimmingView.removeFromSuperview()
            }
        }
    }
}

extension OverlayTransitionAnimator: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let toVC = toVC else {
            return false
        }
        return gestureRecognizer.location(in: toVC.view).y < 50
    }
}

