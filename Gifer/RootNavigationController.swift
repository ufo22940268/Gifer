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
    weak var customDelegate: RootNavigationControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func completeSelectVideo(asset: PHAsset, trimPosition: VideoTrimPosition) {
        print("complete selecting \(asset)")
        (transitioningDelegate as! OverlayTransitionAnimator).interactiveTransition.wantsInteractiveStart = false
        dismiss(animated: true, completion: nil)
        customDelegate?.completeSelectVideo(asset: asset, trimPosition: trimPosition)
    }
    
    func completeSelectPhotos(identifiers: [String]) {
        print("complete selecting photos \(identifiers)")
        (transitioningDelegate as! OverlayTransitionAnimator).interactiveTransition.wantsInteractiveStart = false
        dismiss(animated: true, completion: nil)
    }
}

protocol RootNavigationControllerDelegate: class {
    func completeSelectVideo(asset: PHAsset, trimPosition: VideoTrimPosition)
}
