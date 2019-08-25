//
//  RootNavigationController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/8/25.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Photos

class RootNavigationController: UINavigationController {
    
    enum Mode {
        case normal
        
        // Append new frames to current gif.
        case append
    }
    
    var mode = Mode.normal

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    func completeSelectVideo(asset: PHAsset, trimPosition: VideoTrimPosition) {
        print("complete selecting \(asset)")
        (transitioningDelegate as! OverlayTransitionAnimator).interactiveTransition.wantsInteractiveStart = false
        dismiss(animated: true, completion: nil)
    }
    
    func completeSelectPhotos(identifiers: [String]) {
        print("complete selecting photos \(identifiers)")
        (transitioningDelegate as! OverlayTransitionAnimator).interactiveTransition.wantsInteractiveStart = false
        dismiss(animated: true, completion: nil)
    }
}
