//
//  TestViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/27.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import Photos
import NVActivityIndicatorView

class TestViewController: UIViewController {
    
    @IBOutlet weak var loadingView: NVActivityIndicatorView!
    var customTransitionDelegate = OverlayTransitionAnimator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let vc = AppStoryboard.Main.instance.instantiateViewController(withIdentifier: "root") as! RootNavigationController
            vc.transitioningDelegate = self.customTransitionDelegate
            vc.modalPresentationStyle = .custom
            vc.mode = .append
            self.present(vc, animated: true, completion: nil)
        }
    }
}

extension TestViewController: NVActivityIndicatorViewable {
    
}
