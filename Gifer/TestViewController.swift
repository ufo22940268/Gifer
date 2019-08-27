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

class TestViewController: UIViewController, NVActivityIndicatorViewable {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startAnimating(message: "message", padding: 10, backgroundColor: .green)
    }
    
    
}
