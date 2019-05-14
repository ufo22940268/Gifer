//
//  ConfigViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/5/14.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class ConfigViewController: UIViewController {
    
    var contentView: UIView
    lazy var interactiveAnimator: UIPercentDrivenInteractiveTransition = {
        let animator = UIPercentDrivenInteractiveTransition()
        animator.wantsInteractiveStart = false
        return animator
    }()
    
    lazy var configTransitioningDelegate: ConfigTransitionDelegate = {ConfigTransitionDelegate(interactive: interactiveAnimator)}()
    var centerX: NSLayoutConstraint!

    init(contentView: UIView) {
        self.contentView = contentView
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = configTransitioningDelegate
        
        view.clipsToBounds = true
        view.backgroundColor = .clear
        
        view.addSubview(contentView)
        centerX = contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        NSLayoutConstraint.activate([
            centerX,
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentView.widthAnchor.constraint(equalTo: view.widthAnchor),
            contentView.heightAnchor.constraint(equalTo: view.heightAnchor)
            ])
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        contentView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPan(sender:))))
    }
    
    @objc func onPan(sender: UIPanGestureRecognizer) {
        let progress = sender.translation(in: contentView).x/contentView.bounds.width
        switch sender.state {
        case .began:
            interactiveAnimator.wantsInteractiveStart = true
            dismiss(animated: true, completion: nil)
        case .changed:
            interactiveAnimator.update(progress)
        case .ended:
            if progress > 0.5 || sender.velocity(in: contentView).x > 300 {
                interactiveAnimator.finish()
            } else {
                interactiveAnimator.cancel()
            }
            interactiveAnimator.wantsInteractiveStart = false
        default:
            interactiveAnimator.wantsInteractiveStart = false
            interactiveAnimator.cancel()
        }
    }
}

class ConfigPresentationController: UIPresentationController {
    
    override func presentationTransitionWillBegin() {
        guard let _ = containerView, let presentedView = presentedView, let presentedViewController = presentedViewController as? ConfigViewController, let sourceView = presentingViewController.view else { return }
        presentedView.layer.cornerRadius = 20
        sourceView.layer.cornerRadius = 20
        
        presentedView.frame = frameOfPresentedViewInContainerView
        let presentedContentView = presentedViewController.contentView
        presentedContentView.frame.origin.x = presentedContentView.frame.width
        
        presentedViewController.centerX.constant = presentedViewController.view.bounds.width
        presentedViewController.view.layoutIfNeeded()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onTap(sender:)))
        gesture.cancelsTouchesInView = false
        containerView?.addGestureRecognizer(gesture)
    }
    
    @objc func onTap(sender: UITapGestureRecognizer) {
        if sender.state == .ended && !presentedView!.frame.contains(sender.location(in: containerView)) {
            (presentingViewController as! ShareViewController).tableView.isHidden = true
            presentingViewController.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let height = CGFloat(300)
        var rect = CGRect(origin: CGPoint(x: 0, y: containerView!.bounds.height - height), size: CGSize(width: containerView!.bounds.width, height: height))
        rect = rect.insetBy(dx: 8, dy: 0)
        rect = rect.applying(CGAffineTransform(translationX: 0, y: -containerView!.safeAreaInsets.bottom))
        return rect
    }
}

class ConfigTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let isPresent = transitionContext.viewController(forKey: .to)?.presentingViewController == transitionContext.viewController(forKey: .from)
        var shareVC: ShareViewController
        var configVC: ConfigViewController
        
        if isPresent {
            shareVC = transitionContext.viewController(forKey: .from)! as! ShareViewController
            configVC = transitionContext.viewController(forKey: .to) as! ConfigViewController
        } else {
            shareVC = transitionContext.viewController(forKey: .to)! as! ShareViewController
            configVC = transitionContext.viewController(forKey: .from) as! ConfigViewController
        }
        
        
        let duration = 0.3
        
        if isPresent {
            let toView = transitionContext.view(forKey: .to)!
            transitionContext.containerView.addSubview(toView)
            configVC.view.layoutIfNeeded()
            UIView.animateKeyframes(withDuration: duration, delay: 0, options: [], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                    let tableView = (shareVC ).tableView
                    shareVC.centerX.constant = -tableView.frame.width/3
                    shareVC.view.layoutIfNeeded()
                })
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                    configVC.centerX.constant = 0
                    configVC.view.layoutIfNeeded()
                })
            }) { (success) in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        } else {
            shareVC.centerX.constant = -shareVC.view.bounds.width
            shareVC.view.layoutIfNeeded()
            UIView.animate(withDuration: duration, animations: {
                configVC.centerX.constant = configVC.contentView.bounds.width
                shareVC.centerX.constant = 0
                configVC.view.layoutIfNeeded()
                shareVC.view.layoutIfNeeded()
            }, completion: { success in
                if transitionContext.transitionWasCancelled {
                    transitionContext.completeTransition(false)
                } else {
                    transitionContext.completeTransition(true)
                    configVC.view.removeFromSuperview()
                }
            })
        }
    }
}


