//
//  Wechat.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/16.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import AVKit

struct Wechat {
    
    static var maxShareDuration: Double {
        let threshold: Double!
        #if DEBUG
        threshold = 1
        #else
        threshold = 3
        #endif
        return threshold
    }
    
    static func canBeShared(playerItem: ImagePlayerItem, trimPosition: VideoTrimPosition) -> Bool {
        let activeDuration = playerItem.calibarateTrimPositionDuration(trimPosition)
        let activeCount = playerItem.getActiveFramesBetween(begin: trimPosition.leftTrim, end: trimPosition.rightTrim).count
        return activeDuration.seconds <= Wechat.maxShareDuration || activeCount < 15
    }
}
