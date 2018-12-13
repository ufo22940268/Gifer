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


class ShareManager {
    
    var asset: AVAsset!
    
    init(asset: AVAsset) {
        self.asset = asset
    }
    
    func share() {
//        GifGenerator(video: asset).run()
    }
}
