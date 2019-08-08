//
//  PHAssetExtension.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/8/8.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import Photos

extension PHAsset {
    var size: CGSize {
        return CGSize(width: pixelWidth, height: pixelHeight)
    }
}
