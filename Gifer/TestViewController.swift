//
//  TestViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/27.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class TestViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .yellow
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showTestDialog()
        }
    }
    
    func showTestDialog() {
        let shareVC = ShareViewController()
        shareVC.present(by: self)
    }
}

