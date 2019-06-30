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
    
    var label: String!
    
    lazy var loadingView: LoadingView = {
        return LoadingView(label: self.label)
    }()
    
    convenience init(label: String) {
        self.init(nibName: "LoadingViewController", bundle: nil)
        self.label = label
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.modalPresentationStyle = .custom
        self.modalTransitionStyle = .crossDissolve
        self.transitioningDelegate = self
    }
    
    override func viewDidLoad() {        
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        self.view.layer.cornerRadius = 10
        self.view.addSubview(loadingView)
    }
    
    var estimateSize: CGSize {
        return loadingView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
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

class LoadingView: UIStackView {
    
    var label: String!
    
    lazy var promptView: UILabel = {
        var label = UILabel()
        label.textColor = .white
        label.text = self.label
        label.font = .boldSystemFont(ofSize: 18)
        return label
    }()
    
    lazy var loadingIndicator: UIView = {
        let view = UIActivityIndicatorView(style: .whiteLarge)
        view.startAnimating()
        return view
    }()
    
    convenience init(label: String) {
        self.init(frame: CGRect.zero)
        tintAdjustmentMode = .normal
        self.label = label
        translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(loadingIndicator)
        addArrangedSubview(promptView)
        layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        isLayoutMarginsRelativeArrangement = true
        spacing = 8
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LoadingViewPresentationConstroller: UIPresentationController {
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let frameSize = (presentedViewController as! LoadingViewController).estimateSize
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
    
    var label: String!
    var isShowing: Bool {
        return alertController.isBeingDismissed
    }
    
    lazy var alertController: UIViewController = {
        let vc: LoadingViewController = LoadingViewController(label: label) as LoadingViewController
        return vc
    }()
    
    lazy var activityIndicator: UIView = {
        let indicator = UIActivityIndicatorView()
        indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return indicator
    }()
    
    init(label: String) {
        self.label = label
    }

    func show(by viewController: UIViewController) {
        viewController.present(alertController, animated: false) {
        }
    }
    
    func dismiss() {
        alertController.dismiss(animated: true) {
        }
    }
}
