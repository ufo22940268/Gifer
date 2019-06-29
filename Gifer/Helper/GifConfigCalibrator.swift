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
    let playerItem: ImagePlayerItem
    var initialProcessConfig: GifProcessConfig
    
    init(options: GifGenerator.Options, playerItem: ImagePlayerItem, processConfig: GifProcessConfig) {
        self.options = options
        self.initialProcessConfig = processConfig
        self.playerItem = playerItem
    }
    
    var gifFilePath: URL? {
        get {
            let documentsDirectoryURL: URL? = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            return documentsDirectoryURL?.appendingPathComponent("estimate_animated.gif")
        }
    }
    
    func calibrateSize(under memoryInMB: Double, completion: @escaping (GifProcessConfig) -> Void) {
        let group = DispatchGroup()
        let possibleConfigs = Array(0..<10).reduce([GifProcessConfig](), {(ar, index) in
            var ar = ar
            if ar.isEmpty {
                ar.append(initialProcessConfig)
            } else {
                if let reducedConfig = ar.last!.reduce() {
                    ar.append(reducedConfig)
                }
            }
            return ar
        })
        
        var validConfigs = [GifProcessConfig]()
        for config in possibleConfigs {
            group.enter()
            getEstimateSize(processConfig: config) { (estimateSize) in
                print("estimate size: \(estimateSize) config gif size: \(config.gifSize)")
                if estimateSize < memoryInMB {
                    validConfigs.append(config)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            var finalConfig = validConfigs.max { $0.gifSize.width < $1.gifSize.width }
            
            if finalConfig == nil {
                print("using lowest config")
                finalConfig = self.initialProcessConfig.lowestConfig(for: self.shareType)
            }
            
            print("finalConfig: \(String(describing: finalConfig))")
            completion(finalConfig!)
        }
    }
    
    var shareType: ShareType {
        return options.exportType!
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
        generateGif(processConfig: processConfig) { file in
            completion(file.fileSizeInMB)
        }
    }
    
    func generateGif(processConfig: GifProcessConfig, completion: @escaping (URL) -> Void) {
        let fileProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]]  as CFDictionary
        let fileURL: URL? = self.gifFilePath
        
        guard let url = fileURL as CFURL?, let destination = CGImageDestinationCreateWithURL(url, kUTTypeGIF, 1, nil) else { fatalError() }
        CGImageDestinationSetProperties(destination, fileProperties)

        var image = playerItem.activeFrames.first!.uiImage
        let size = AVMakeRect(aspectRatio: image.size, insideRect: CGRect(origin: .zero, size: processConfig.gifSize)).size
        image = UIGraphicsImageRenderer(size: size).image { (context) in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        
        let cgImage = image.cgImage!
        let frameProperties: CFDictionary = [(kCGImagePropertyGIFDictionary as String): [(kCGImagePropertyGIFUnclampedDelayTime as String): processConfig.gifDelayTime]] as CFDictionary
        CGImageDestinationAddImage(destination, cgImage, frameProperties)
        CGImageDestinationFinalize(destination)
        completion(fileURL!)
    }
}
