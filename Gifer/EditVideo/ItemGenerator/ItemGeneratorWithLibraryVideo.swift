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

class ItemGeneratorWithLibraryVideo: ItemGenerator {
    
    let videoAsset: PHAsset
    var downloadTaskId: PHImageRequestID?
    var avGenerator: ItemGeneratorWithAVAsset?
    var avGeneratorPercent = CGFloat(0.3)
    var progressDelegate: GenerateProgressDelegate?
    var trimPosition: VideoTrimPosition
    
    init(video: PHAsset, trimPosition: VideoTrimPosition? = nil) {
        videoAsset = video
        self.trimPosition = trimPosition ?? VideoTrimPosition(leftTrim: .zero, rightTrim: video.duration.toTime())
    }
    
    func run(complete: @escaping (ImagePlayerItem) -> Void) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .mediumQualityFormat
        if let downloadTaskId = downloadTaskId {
            PHImageManager.default().cancelImageRequest(downloadTaskId)
        }
        options.progressHandler = { (progress, _, _, _) in
            self.progressDelegate?.onProgress(CGFloat(progress)*(1 - self.avGeneratorPercent))
        }
        
        downloadTaskId = PHImageManager.default().requestAVAsset(forVideo: videoAsset, options: options) { [weak self] (avAsset, _, _) in
            guard let self = self, let avAsset = avAsset else { return }
            self.avGenerator = ItemGeneratorWithAVAsset(avAsset: avAsset, asset: self.videoAsset, trimPosition: self.trimPosition)
            self.avGenerator?.progressDelegate = self
            self.avGenerator?.run(complete: complete)
        }
    }
    
    func destroy() {
        if let downloadTaskId = downloadTaskId {
            PHImageManager.default().cancelImageRequest(downloadTaskId)
        }
    }
}


// MARK: Video download progress
extension ItemGeneratorWithLibraryVideo: GenerateProgressDelegate {
    func onProgress(_ progress: CGFloat) {
        progressDelegate?.onProgress(1 - avGeneratorPercent + progress*avGeneratorPercent)
    }
}

