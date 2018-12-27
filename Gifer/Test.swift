//
//  Test.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/11/10.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import Photos
import UIKit

func getTestVideo() -> PHAsset {
    let asset = PHAsset.fetchAssets(with: .video, options: nil).object(at: 1)
    return asset
}
