//
//  ItemGeneratorWithLibraryPhotos.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/9/13.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import Photos
import UIKit
import Photos

class ItemGeneratorWithLibraryPhotos: ItemGenerator {
    var progressDelegate: GenerateProgressDelegate?
    let identifiers: [String]
    var requestIds: [Int32] = [Int32]()
    var mode: EditViewController.Mode {
        return .photo
    }

    internal init(identifiers: [String]) {
        self.identifiers = identifiers
    }

    func run(complete: @escaping (ImagePlayerItem) -> Void) {
        var images = Array<UIImage?>(repeating: nil, count: identifiers.count)
        let group = DispatchGroup()
        identifiers.forEach { _ in group.enter() }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        
        let progressStepCount = CGFloat(assets.count + 1)
        var progressStep = CGFloat(0)
        
        let targetSize = AVMakeRect(aspectRatio: CGSize(width: assets.firstObject!.pixelWidth, height: assets.firstObject!.pixelHeight), insideRect: CGRect(origin: .zero, size: CGSize(width: 600, height: 600))).size
        assets.enumerateObjects { (asset, index, _) in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            let id = PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options, resultHandler: { (image, _) in
                images[index] = image
                group.leave()
            })
            self.requestIds.append(id)
            progressStep += 1
            self.progressDelegate?.onProgress(progressStep/progressStepCount)
        }
        
        group.notify(queue: .main) {
            ImagePlayerFrame.initDirectory()
            var frames = [ImagePlayerFrame]()
            guard (images.allSatisfy { $0 != nil }) else {
                fatalError()
            }
            for (index, image) in images.enumerated() {
                let time = CMTimeMultiply(Double(1).toTime(), multiplier: Int32(index))
                let frame = ImagePlayerFrame(time: time, image: image!)
                frames.append(frame)
            }
            let playerItem = ImagePlayerItem(frames: frames, duration: CMTimeMultiply(Double(1).toTime(), multiplier: Int32(frames.count)))
            self.progressDelegate?.onComplete()
            complete(playerItem)
        }
    }
    
    func destroy() {
        requestIds.forEach { PHImageManager.default().cancelImageRequest($0) }
    }
}
