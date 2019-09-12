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
    
    @IBOutlet weak var progressView: VideoProgressLoadingIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressView.progress = 0
        count()
    }
    
    func count() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            if self.progressView.progress <= 1 {
                self.progressView.progress = self.progressView.progress + 0.01
                self.count()
            }
        }
    }
}
