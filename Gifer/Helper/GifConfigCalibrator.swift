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

extension URL {
    var attributes: [FileAttributeKey : Any]? {
        do {
            return try FileManager.default.attributesOfItem(atPath: path)
        } catch let error as NSError {
            print("FileAttribute error: \(error)")
        }
        return nil
    }
    
    var fileSize: UInt64 {
        return attributes?[.size] as? UInt64 ?? UInt64(0)
    }
    
    var fileSizeInMB: Double {
        return Double(fileSize)/pow(1024, 2)
    }

    var fileSizeString: String {
        return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }
    
    var creationDate: Date? {
        return attributes?[.creationDate] as? Date
    }
}

class GifConfigCalibrator {
    
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
        let group = DispatchGroup()
        let possibleConfigs = Array(0..<3).reduce([GifProcessConfig](), {(ar, index) in
            var ar = ar
            if ar.isEmpty {
                ar.append(initialProcessConfig)
            } else {
                ar.append(ar.last!.reduce())
            }
            return ar
        })
        
        var finished = false
        var finalConfig: GifProcessConfig!
        for config in possibleConfigs {
            if !finished {
                group.enter()
            } else {
                break
            }
            getEstimateSize(processConfig: config) { (estimateSize) in
                if estimateSize < memoryInMB {
                    finished = true
                    finalConfig = config
                }
                group.leave()
            }
        }
        
        if finalConfig == nil {
            print("using lowest config")
            finalConfig = initialProcessConfig.lowestConfig
        }
        
        group.notify(queue: .main) {
            print("finalConfig: \(String(describing: finalConfig))")
        }
    }
    
    private func getEstimateSize(processConfig: GifProcessConfig, completion: @escaping (Double) -> Void) {
        getSize(processConfig: processConfig, sample: true) { (sampleSize) in
            let sliceCount = self.options.splitVideo(extractedImageCountPerSecond: processConfig.extractImageCountPerSecond).count
            var estimateSize = sampleSize*Double(sliceCount)
            //Increase estimate size. Because the estimate size will be smaller than real size for sometime.
            estimateSize = estimateSize + estimateSize*0.2
            completion(estimateSize)
        }
    }
    
    private func getSize(processConfig: GifProcessConfig, sample: Bool, completion: @escaping (Double) -> Void) {
        var times = options.splitVideo(extractedImageCountPerSecond: processConfig.extractImageCountPerSecond)
        if sample {
            times = Array(times[0...0])
        }
        generateGif(processConfig: processConfig, in: times) { file in
            completion(file.fileSizeInMB)
        }
    }
    
    func generateGif(processConfig: GifProcessConfig, in times: [CMTime], completion: @escaping (URL) -> Void) {
        let times = times.map { NSValue(time: $0) }
        let fileProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]]  as CFDictionary
        let fileURL: URL? = self.gifFilePath
        
        guard let url = fileURL as CFURL?, let destination = CGImageDestinationCreateWithURL(url, kUTTypeGIF, times.count, nil) else { fatalError() }
        CGImageDestinationSetProperties(destination, fileProperties)
        
        let generator: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        generator.maximumSize = processConfig.gifSize
        generator.generateCGImagesAsynchronously(forTimes: times) { (requestTime, cgImage, time, _, _) in
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
