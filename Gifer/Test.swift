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
    let options = PHFetchOptions()
    options.predicate = NSPredicate(format: "isFavorite = true")
    let assets: PHFetchResult<PHAsset> = PHAsset.fetchAssets(with: .video, options: options)
    return assets.lastObject!
}

func getTestAVAsset(complete: @escaping (AVAsset) -> Void) {
    let asset = getTestVideo()
    let options = PHVideoRequestOptions()
    options.isNetworkAccessAllowed = true
    PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { (asset, ni, nil) in
        complete(asset!)
    }
}

func getTestPlayerItem(complete: @escaping (ImagePlayerItem) -> Void) {
    getTestAVAsset { (avAsset) in
        ImagePlayerItemGenerator(avAsset: avAsset, trimPosition: VideoTrimPosition(leftTrim: .zero, rightTrim: avAsset.duration))
            .run(complete: { (item) in
                complete(item)
            })
    }
}
