//
//  ImagePlayerItem.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/26.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit

class ImagePlayerItem {
    var frames: [ImagePlayerFrame]
    var duration: CMTime    
    
    init(frames: [ImagePlayerFrame], duration: CMTime) {
        self.frames = frames
        self.duration = duration
    }
    
    func nearestIndex(time: CMTime) -> Int {
        return (self.frames.enumerated().min(by: { abs(($0.1.time - time).seconds) < abs(($1.1.time - time).seconds) }))!.0
    }
}
