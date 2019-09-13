//
//  ItemGeneratorWithLibraryLivePhoto.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/9/13.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation

import AVKit
import UIKit
import Photos

class ItemGeneratorWithLibraryLivePhoto: ItemGenerator, ItemGeneratorFPSAdjustable {
    
    let livePhotoAsset: PHAsset
    var downloadTaskId: PHImageRequestID?
    var avGenerator: ItemGeneratorWithAVAsset?
    var avGeneratorPercent = CGFloat(0.3)
    var progressDelegate: GenerateProgressDelegate?
    
    var mode: EditViewController.Mode {
        return .livePhoto
    }
    
    var fps: FPSFigure = .default

    init(livePhoto: PHAsset) {
        livePhotoAsset = livePhoto
    }
    
    func run(complete: @escaping (ImagePlayerItem) -> Void) {
        let options = PHLivePhotoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .fastFormat
        if let downloadTaskId = downloadTaskId {
            PHImageManager.default().cancelImageRequest(downloadTaskId)
        }
        
        options.progressHandler = { (progress, _, _, _) in
            self.progressDelegate?.onProgress(CGFloat(progress)*(1 - self.avGeneratorPercent))
        }
        
        downloadTaskId = PHImageManager.default().requestLivePhoto(for: livePhotoAsset, targetSize: CGSize(width: 700, height: 700), contentMode: .aspectFit, options: options) { (photo, info) in
            if let info = info, info[PHImageErrorKey] != nil {
                print("error: \(String(describing: info[PHImageErrorKey]))")
                return
            }
            let url = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("livePhoto.mov")
            try? FileManager.default.removeItem(at: url)
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            PHAssetResourceManager.default().writeData(for: PHAssetResource.assetResources(for: photo!).first { $0.type == PHAssetResourceType.pairedVideo }!, toFile: url, options: options, completionHandler: { [weak self] (error) in
                guard let self = self else { return }
                let avAsset: AVAsset = AVAsset(url: url)
                
                self.progressDelegate?.onProgress(1 - self.avGeneratorPercent)
                
                self.avGenerator = ItemGeneratorWithAVAsset(avAsset: avAsset, asset: self.livePhotoAsset, trimPosition: avAsset.trimPosition, fps: self.fps)
                self.avGenerator?.progressDelegate = self
                self.avGenerator?.run(complete: complete)
            })
        }
    }
    
    func destroy() {
        if let downloadTaskId = downloadTaskId {
            PHImageManager.default().cancelImageRequest(downloadTaskId)
        }
    }
}


// MARK: Video download progress
extension ItemGeneratorWithLibraryLivePhoto: GenerateProgressDelegate {
    func onProgress(_ progress: CGFloat) {
        progressDelegate?.onProgress(1 - avGeneratorPercent + progress*avGeneratorPercent)
    }
}

