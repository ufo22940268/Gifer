//
//  LoadingDialog.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/12/21.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView

protocol Dialog {
    func show(by viewController: UIViewController)
    func dismiss(animated: Bool)
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
        let view = NVActivityIndicatorView(frame: CGRect(origin: .zero, size: CGSize(width: 44, height: 44)), type: nil, color: .white, padding: 0)
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

fileprivate class DimmingView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if alpha == 1 {
            return self
        } else {
            return super.hitTest(point, with: event)
        }
    }
}

class LoadingViewPresentationConstroller: UIPresentationController {
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let frameSize = (presentedViewController as! LoadingViewController).estimateSize
        return CGRect(origin: presentingViewController.view.center.applying(CGAffineTransform(translationX: -frameSize.width/2, y: -frameSize.height/2)), size: frameSize)
    }
    
    override var presentationStyle: UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    override var shouldPresentInFullscreen: Bool {
        return true
    }
    
    lazy var dimmingView: UIView = {
        let view = DimmingView()
        view.alpha = 0.0
        view.frame = self.containerView!.bounds
        view.isUserInteractionEnabled = true
        return view
    }()
    
    override func presentationTransitionWillBegin() {
        self.containerView?.isUserInteractionEnabled = false
        self.containerView?.addSubview(dimmingView)
        dimmingView.addSubview(presentedView!)
        dimmingView.alpha = 0
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (_) in
            self.dimmingView.alpha = 1.0
        }, completion: nil)
    }
    
    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (_) in
            self.dimmingView.alpha = 0
        }, completion: { (_) in
            self.dimmingView.removeFromSuperview()
        })
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
    
    init(label: String) {
        self.label = label
    }

    func show(by viewController: UIViewController) {
        alertController.dismiss(animated: false, completion: nil)
        viewController.present(alertController, animated: false) {}
    }
    
    func dismiss(animated: Bool = true) {
        alertController.dismiss(animated: true) {
        }
    }
}
