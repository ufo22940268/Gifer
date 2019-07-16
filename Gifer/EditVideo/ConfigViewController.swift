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
    var centerX: NSLayoutConstraint!
    var customTransitionDelegate: ShareTransitioningDelegate!
    lazy var interactiveAnimator: ShareInteractiveAnimator = {
        let animator = ShareInteractiveAnimator()
        animator.wantsInteractiveStart = false
        return animator
    }()
    lazy var panGesture: UIPanGestureRecognizer = {
        return UIPanGestureRecognizer(target: self, action: #selector(onPan(sender:)))
    }()

    init(contentView: UIView) {
        self.contentView = contentView
        super.init(nibName: nil, bundle: nil)
        
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
        customTransitionDelegate = ShareTransitioningDelegate(dismiss: {}, interator: interactiveAnimator)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.transitioningDelegate = customTransitionDelegate
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        navigationController?.interactivePopGestureRecognizer?.canPrevent(panGesture)
    }
    
    @objc func onPan(sender: UIPanGestureRecognizer) {
        let progress = sender.translation(in: view).y/view.bounds.height
        switch sender.state {
        case .began:
            self.dismiss(animated: true, completion: nil)
            interactiveAnimator.wantsInteractiveStart = true
        case .changed:
            interactiveAnimator.update(progress)
        case .ended:
            if progress > 0.5 {
                interactiveAnimator.finish()
            } else {
                interactiveAnimator.cancel()
            }
            interactiveAnimator.wantsInteractiveStart = false
        default:
            break
        }
    }
}

extension ConfigViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer == panGesture {
            return true
        }
        
        return false
    }
}
