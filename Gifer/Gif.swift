//
//  Gif.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/11/9.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import ImageIO
import MobileCoreServices
import Photos

extension AVAsset {
    
    func extractThumbernails() -> [UIImage] {
        var images = [UIImage]()
        
        let imageCount = 10
        let generator = AVAssetImageGenerator(asset: self)
        for i in 0..<imageCount {
            let time = CMTime(value: CMTimeValue(Double(self.duration.value)/Double(imageCount)*Double(i)), timescale: 600)
            let cgImage = try! generator.copyCGImage(at: time, actualTime: nil)
            images.append(UIImage(cgImage: cgImage))
        }
        return images
    }
}

class GifGenerator {
    
    let fileName = "animated.gif"
    var videoAsset: PHAsset
    
    init(video: PHAsset) {
        self.videoAsset = video
    }
    
    func buildDestinationOfGif(frameCount: Int) -> CGImageDestination {
        let fileProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]]  as CFDictionary
        let documentsDirectoryURL: URL? = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL: URL? = documentsDirectoryURL?.appendingPathComponent("animated.gif")
        
        if let url = fileURL as CFURL? {
            if let destination = CGImageDestinationCreateWithURL(url, kUTTypeGIF, frameCount, nil) {
                CGImageDestinationSetProperties(destination, fileProperties)
                return destination
            }
        }
        
        fatalError()
    }
    
    func run(complete: @escaping () -> Void) {
        let manager = PHImageManager.default()
        manager.requestAVAsset(forVideo: videoAsset, options: nil) { (avAsset, _, info) in
            if let avAsset = avAsset {
                var times = [NSValue]()
                let frameCounts: Int = Int(avAsset.duration.seconds)
                let group = DispatchGroup()
                for second in 0..<frameCounts {
                    times.append(NSValue(time: CMTimeMakeWithSeconds(Float64(second), preferredTimescale: 1)))
                    group.enter()
                }
                let destination = self.buildDestinationOfGif(frameCount: Int(avAsset.duration.seconds))
                AVAssetImageGenerator(asset: avAsset).generateCGImagesAsynchronously(forTimes: times, completionHandler: { (_, image, _, _, error) in
                    let frameProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [(kCGImagePropertyGIFDelayTime as String): 0.01]] as CFDictionary
                    CGImageDestinationAddImage(destination, image!, frameProperties)
                    group.leave()
                })
                
                
                group.notify(queue: .global()) {
                    if !CGImageDestinationFinalize(destination) {
                        print("Failed to finalize the image destination")
                    }
                    print("finish")
                    complete()
                }
            }
        }
    }

}
