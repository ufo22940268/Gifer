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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let dialog: LoadingDialog = LoadingDialog(label: "show loading dialog")
            dialog.show(by: self)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dialog.dismiss()
            }
        }
    }
    
    @IBAction func onTapRootView(_ sender: Any) {
        print("onTapRootView")
    }
}
