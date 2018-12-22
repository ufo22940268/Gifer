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
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.modalPresentationStyle = .overCurrentContext
        self.modalTransitionStyle = .crossDissolve
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.red
        self.view.addSubview(view)
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 200),
            view.heightAnchor.constraint(equalToConstant: 200),
            view.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
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
        let vc: LoadingViewController = LoadingViewController()
        viewController.present(vc, animated: true) {
            
        }
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
