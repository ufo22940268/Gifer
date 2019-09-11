//
//  ItemGeneratorWithPHAsset.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/9/11.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import AVKit
import UIKit
import Photos



class ItemGeneratorWithPHVideoAsset: ItemGenerator {
    
    let videoAsset: PHAsset
    var downloadTaskId: PHImageRequestID?
    var avGenerator: ItemGeneratorWithAVAsset?
    
    init(video: PHAsset) {
        videoAsset = video
    }
    
    func run(complete: @escaping (ImagePlayerItem) -> Void) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .mediumQualityFormat
        if let downloadTaskId = downloadTaskId {
            PHImageManager.default().cancelImageRequest(downloadTaskId)
        }
        
        downloadTaskId = PHImageManager.default().requestAVAsset(forVideo: videoAsset, options: options) { [weak self] (avAsset, _, _) in
            guard let self = self, let avAsset = avAsset else { return }
            self.avGenerator = ItemGeneratorWithAVAsset(avAsset: avAsset, asset: self.videoAsset, trimPosition: avAsset.trimPosition)
            self.avGenerator?.run(complete: complete)
        }
    }
    
    func destroy() {
        if let downloadTaskId = downloadTaskId {
            PHImageManager.default().cancelImageRequest(downloadTaskId)
        }
    }
}
