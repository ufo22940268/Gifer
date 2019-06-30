//
//  FramePreviewViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/29.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class FramePreviewViewController: UIViewController {

    @IBOutlet weak var previewView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        DarkMode.enable(in: self)
        view.backgroundColor = UIColor(named: "darkBackgroundColor")
        view.tintColor = .yellowActiveColor
        navigationController?.view.tintColor = .yellowActiveColor
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func onDismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
