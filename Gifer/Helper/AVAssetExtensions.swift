//
//  AVAssetExtensions.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/9/11.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import AVKit

extension AVAsset {
    var trimPosition: VideoTrimPosition {
        return VideoTrimPosition(leftTrim: .zero, rightTrim: duration)
    }
}
