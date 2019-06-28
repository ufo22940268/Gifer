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
    let assets: PHFetchResult<PHAsset> = PHAsset.fetchAssets(with: .video, options: nil)
    return assets.firstObject!
}
