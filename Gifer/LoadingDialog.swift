//
//  LoadingDialog.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/12/21.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

protocol Dialog {
    func show(by viewController: UIViewController)
    func dismiss()
}


class LoadingViewController: UIViewController {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.modalPresentationStyle = .custom
        self.modalTransitionStyle = .crossDissolve
        self.transitioningDelegate = self
    }
    
    override func viewDidLoad() {        
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.yellow
        self.view.layer.cornerRadius = 10
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension LoadingViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return LoadingViewPresentationConstroller(presentedViewController: presented, presenting: presenting)
    }
}

class LoadingViewPresentationConstroller: UIPresentationController {
    
    private let frameSize = CGSize(width: 100, height: 100)
    
    override var frameOfPresentedViewInContainerView: CGRect {
        return CGRect(origin: presentingViewController.view.center.applying(CGAffineTransform(translationX: -frameSize.width/2, y: -frameSize.height/2)), size: frameSize)
    }
    
    lazy var dimmingView: UIView = {
        let view = UIView()
        view.alpha = 0.0
        view.frame = self.containerView!.bounds
        return view
    }()
    
    override func presentationTransitionWillBegin() {
        self.containerView?.addSubview(dimmingView)
        dimmingView.addSubview(presentedView!)
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { (_) in
            self.dimmingView.alpha = 1.0
        }, completion: nil)
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        if !completed {
            dimmingView.removeFromSuperview()
        }
    }
}

class LoadingDialog: Dialog {
    
    var alertController: UIViewController!
    
    lazy var activityIndicator: UIView = {
        let indicator = UIActivityIndicatorView()
        indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return indicator
    }()
    
    init() {
    }

    func show(by viewController: UIViewController) {
        let vc: LoadingViewController = LoadingViewController(nibName: "LoadingViewController", bundle: nil) as LoadingViewController
        viewController.present(vc, animated: true) {

        }
        
//        alertController = UIAlertController(title: "adsff", message: nil, preferredStyle: .alert)
//        viewController.present(alertController, animated: true) {
//
//        }
    }
    
    func dismiss() {
//        alertController.dismiss(animated: true) {
//
//        }
    }
}
