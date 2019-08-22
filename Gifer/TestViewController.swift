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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startAnimating(message: "adsfadfs")
    }
}

extension TestViewController: NVActivityIndicatorViewable {
    
}
