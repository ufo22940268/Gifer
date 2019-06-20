//
//  TestViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/27.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class TestViewController: UIViewController {
    
    @IBOutlet weak var p: VideoProgressLoadingIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.p.progress = 0.4
            self.p.progress = 0.8
        }
    }
}

