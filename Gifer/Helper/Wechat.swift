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
    
    static func canBeShared(duration: CMTime) -> Bool {
        return duration.seconds <= Wechat.maxShareDuration
    }
}
