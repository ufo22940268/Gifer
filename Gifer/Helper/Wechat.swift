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
    static func canBeShared(duration: CMTime) -> Bool {
        return duration.seconds < 1
    }
}
