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

let frameCountLimitation = 200

class RootNavigationController: UINavigationController {
    
    enum Mode {
        case normal
        
        // Append new frames to current gif.
        case append
    }
    
    var mode = Mode.normal
    var appendFPS: FPSFigure?
    var currentFrameCount: Int?
    weak var customDelegate: RootNavigationControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func isExceedFrameLimit(asset: PHAsset) -> Bool {
        guard let fps = appendFPS, let currentCount = currentFrameCount else { fatalError() }
        let duration = asset.duration
        return currentCount + Int(duration/(1/Double(fps.rawValue))) > frameCountLimitation
    }
    
    func isExceedFrameLimit(newFrames: Int) -> Bool {
        return currentFrameCount! + newFrames > frameCountLimitation
    }
    
    func promptForExceedFrameLimit() {
        makeToast(message: NSLocalizedString("Too much frames", comment: ""))
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
        customDelegate?.completeSelectPhotos(identifiers: identifiers)
    }
}

protocol RootNavigationControllerDelegate: class {
    func completeSelectVideo(asset: PHAsset, trimPosition: VideoTrimPosition)
    func completeSelectPhotos(identifiers: [String])
}
