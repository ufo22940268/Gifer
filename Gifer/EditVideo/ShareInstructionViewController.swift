//
//  ShareInstructionViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/17.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class ShareInstructionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        DarkMode.enable(in: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    @IBAction func onOkTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print(view.frame)
    }
}
