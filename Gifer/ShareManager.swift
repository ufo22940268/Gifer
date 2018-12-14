//
//  ShareManager.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/12/13.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import ImageIO
import MobileCoreServices
import Photos
import MonkeyKing

class ShareManager {
    
    var asset: AVAsset!
    var startProgress: CGFloat!
    var endProgress: CGFloat!
    
    init(asset: AVAsset, startProgress: CGFloat, endProgress: CGFloat) {
        self.asset = asset
        self.startProgress = startProgress
        self.endProgress = endProgress
    }
    
    func share() {
        GifGenerator(video: asset).run(start: self.startProgress, end: self.endProgress) { path in
            
        }
    }
}
