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
            overlayView.topAnchor.constraint(equalTo: transitionContext.containerView.topAnchor, constant: 80),
            overlayView.leadingAnchor.constraint(equalTo: transitionContext.containerView.leadingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: transitionContext.containerView.bottomAnchor),
            overlayView.widthAnchor.constraint(equalTo: transitionContext.containerView.widthAnchor),
            ])
        transitionContext.containerView.layoutIfNeeded()
        let panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onPanToDismiss(_:)))
        overlayView.addGestureRecognizer(panGesture)
        panGesture.delegate = self
        overlayView.transform = CGAffineTransform(translationX: 0, y: overlayView.bounds.height)
        fromView.backgroundColor = #colorLiteral(red: 0.06274509804, green: 0.06274509804, blue: 0.06274509804, alpha: 1)
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseOut, animations: {
            fromView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            fromView.clipsToBounds = true
            fromView.layer.cornerRadius = 16
            overlayView.transform = .identity
            overlayView.superview?.layoutIfNeeded()
        }) { (_) in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    fileprivate func animateTransitionForDismissal(in transitionContext: UIViewControllerContextTransitioning) {
        _ = transitionContext.viewController(forKey: .from)
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
        let topVC: UIViewController? = (transitionContext.viewController(forKey: .to) as? UINavigationController)?.topViewController
        let isPresent = topVC is VideoGalleryViewController || topVC is VideoRangeViewController
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
        
        var overlayStackView: UIStackView!
        @IBOutlet weak var overlayTopBar: UIView!
        
        lazy var dimmingView: UIView = {
            let view = UIView().useAutoLayout()
            view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            return view
        }()

        override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
            super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
            overlayStackView = Bundle.main.loadNibNamed("OverlayTopView", owner: self, options: nil)?.first as? UIStackView
            overlayStackView.useAutoLayout()
            overlayTopBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            overlayTopBar.layer.cornerRadius = 12
            overlayTopBar.clipsToBounds = true
            
            let galleryView = super.presentedViewController.view!
            galleryView.backgroundColor = .orange
            galleryView.useAutoLayout()
            overlayStackView.addArrangedSubview(galleryView)
            NSLayoutConstraint.activate([
                overlayStackView.widthAnchor.constraint(equalTo: galleryView.widthAnchor)
                ])
            
            overlayStackView.layoutIfNeeded()
        }
        
        override var presentedView: UIView? {
            return overlayStackView
        }

        override func presentationTransitionWillBegin() {
            dimmingView.removeFromSuperview()
            containerView?.insertSubview(dimmingView, at: 0)
            dimmingView.useSameSizeAsParent()
            dimmingView.alpha = 0
            presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (context) in
                self.dimmingView.alpha = 1
            }, completion: nil)
        }
        
        override func dismissalTransitionWillBegin() {
            dimmingView.alpha = 1
            presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (context) in
                self.dimmingView.alpha = 0
            }, completion: nil)
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

