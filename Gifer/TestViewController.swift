//
//  TestViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/27.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import Photos

class TestViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gifURL = GifGenerator.animatedGifFilePath!
        let gifData = try! Data(contentsOf: gifURL)
        let activityVC = UIActivityViewController(activityItems: [gifData], applicationActivities: nil)
        present(activityVC, animated: true, completion: nil)
    }
}
