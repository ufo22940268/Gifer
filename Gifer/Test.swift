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

func getTestAVAsset(complete: @escaping (AVAsset, PHAsset) -> Void) {
    let asset = getTestVideo()
    let options = PHVideoRequestOptions()
    options.isNetworkAccessAllowed = true
    PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { (avAsset, _, _) in
        complete(avAsset!, asset)
    }
}

func getTestPlayerItem(complete: @escaping (ImagePlayerItem, PHAsset) -> Void) {
    getTestAVAsset { (avAsset, phAsset) in
        ItemGeneratorWithAVAsset(avAsset: avAsset, asset: phAsset, trimPosition: VideoTrimPosition(leftTrim: .zero, rightTrim: avAsset.duration))
            .run(complete: { (item) in
                complete(item, phAsset)
            })
    }
}
