//
//  ItemGeneratorWithVideoFile.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/9/6.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import AVKit
import UIKit

class ItemGeneratorWithVideoFile: ItemGenerator {
    
    let url: URL
    var avAssetGenerator: ItemGeneratorWithAVAsset?
    
    init(url: URL) {
        self.url = url
    }
    
    func run(complete: @escaping (ImagePlayerItem) -> Void) {
        let asset: AVAsset = AVAsset(url: url)
        avAssetGenerator = ItemGeneratorWithAVAsset(avAsset: asset, trimPosition: VideoTrimPosition(leftTrim: .zero, rightTrim: asset.duration), fps: .default, shouldCleanDirectory: false)
        avAssetGenerator?.run(complete: complete)
    }
    
    func destroy() {
        avAssetGenerator?.destroy()
    }
}
