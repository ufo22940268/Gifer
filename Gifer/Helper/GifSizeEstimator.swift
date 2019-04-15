//
//  GifSizeEstimator.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/4/15.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import AVKit
import ImageIO
import MobileCoreServices

class GifSizeEstimator {
    
    let options: GifGenerator.Options
    var asset: AVAsset
    var initialProcessConfig: GifProcessConfig
    
    init(options: GifGenerator.Options, asset: AVAsset, processConfig: GifProcessConfig) {
        self.options = options
        self.asset = asset
        self.initialProcessConfig = processConfig
    }
    
    var gifFilePath: URL? {
        get {
            let documentsDirectoryURL: URL? = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            return documentsDirectoryURL?.appendingPathComponent("estimate_animated.gif")
        }
    }
    
    func calibrateSize(under memoryInMB: Double, completion: @escaping () -> Void) {
        getSize(processConfig: initialProcessConfig) {
            print("size: \($0)")
            completion()
        }
    }
    
    private func getSize(processConfig: GifProcessConfig, completion: @escaping (Int) -> Void) {
        let times = options.splitVideo(extractedImageCountPerSecond: processConfig.extractImageCountPerSecond)
        generateGif(processConfig: processConfig, in: times) { file in
            completion(10)
        }
    }
    
    func generateGif(processConfig: GifProcessConfig, in times: [CMTime], completion: @escaping (URL) -> Void) {
        let times = times.map { NSValue(time: $0) }
        let fileProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]]  as CFDictionary
        let fileURL: URL? = self.gifFilePath
        
        guard let url = fileURL as CFURL?, let destination = CGImageDestinationCreateWithURL(url, kUTTypeGIF, times.count, nil) else { fatalError() }
        CGImageDestinationSetProperties(destination, fileProperties)
        
        AVAssetImageGenerator(asset: asset).generateCGImagesAsynchronously(forTimes: times) { (requestTime, cgImage, time, _, _) in
            guard let cgImage = cgImage else { return }
            
            let frameProperties: CFDictionary = [(kCGImagePropertyGIFDictionary as String): [(kCGImagePropertyGIFUnclampedDelayTime as String): processConfig.gifDelayTime]] as CFDictionary
            CGImageDestinationAddImage(destination, cgImage, frameProperties)
            
            if requestTime == times.last!.timeValue {
                CGImageDestinationFinalize(destination)
                completion(fileURL!)
            }
        }
    }
}
