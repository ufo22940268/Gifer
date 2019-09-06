//
//  ItemGeneratorWithAVAsset.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/9/6.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import AVKit
import UIKit
import Photos

class ItemGeneratorWithAVAsset: ItemGenerator {
    
    var avAsset: AVAsset
    var asset: PHAsset
    var trimPosition: VideoTrimPosition
    var isDestroyed = false
    
    let generatorParallelNumber: Int = 4
    var fps: FPSFigure?
    let shouldCleanDirectory: Bool
    
    lazy var generators:[AVAssetImageGenerator]  = {
        return (0..<self.generatorParallelNumber).map { _ in
            return createAssetGenerator()
        }
    }()
    
    internal init(avAsset: AVAsset, asset: PHAsset, trimPosition: VideoTrimPosition, fps: FPSFigure? = nil, shouldCleanDirectory: Bool = true) {
        self.avAsset = avAsset
        self.asset = asset
        self.trimPosition = trimPosition
        self.fps = fps
        self.shouldCleanDirectory = shouldCleanDirectory
    }
    
    func createAssetGenerator() -> AVAssetImageGenerator {
        let generator = AVAssetImageGenerator(asset: avAsset)
        generator.maximumSize = CGSize(width: 1200, height: 1200)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
        return generator
    }
    
    func splitTimes() -> [NSValue] {
        var t = trimPosition.leftTrim
        var interval: CMTime
        if let fps = fps {
            interval = CMTime(seconds: 1/Double(fps.rawValue), preferredTimescale: 600)
        } else {
            interval = CMTime(seconds: 0.2, preferredTimescale: 600)
        }
        var ar = [NSValue]()
        while t + interval < trimPosition.rightTrim {
            ar.append(NSValue(time: t))
            t = t + interval
        }
        
        if ar.last!.timeValue != trimPosition.rightTrim {
            ar[ar.count - 1] = NSValue(time: trimPosition.rightTrim)
        }
        
        return ar
    }
    
    func run(complete: @escaping (ImagePlayerItem) -> Void) {
        let times = splitTimes()
        
        var timeSegments = [[NSValue]]()
        let step = Int(floor(Float(times.count)/Float(generatorParallelNumber)))
        var frameSegments = [[ImagePlayerFrame]]()
        for i in stride(from: 0, to: times.count, by: step) {
            if timeSegments.count == generatorParallelNumber - 1 {
                timeSegments.append(Array(times[i..<times.count]))
            } else {
                timeSegments.append(Array(times[i..<min(i + step, times.count)]))
            }
            frameSegments.append([ImagePlayerFrame]())
        }
        
        if shouldCleanDirectory {
            ImagePlayerFrame.initDirectory()
        }
        
        let group = DispatchGroup()
        var size: CGSize!
        for index in 0..<generatorParallelNumber {
            group.enter()
            let times = timeSegments[index]
            var processedCount = 0
            generators[index].generateCGImagesAsynchronously(forTimes: times) { (time, image, _, result, error) in
                processedCount = processedCount + 1
                autoreleasepool {
                    guard let image = image, error == nil, result == .succeeded, !self.isDestroyed else {
                        if processedCount == times.count {
                            group.leave()
                        }
                        return
                    }
                    
                    if size == nil {
                        size = image.size
                    }
                    var frames = frameSegments[index]
                    var frame = ImagePlayerFrame(time: time - self.trimPosition.leftTrim)
                    frame.saveToDirectory(cgImage: image)
                    frames.append(frame)
                    frameSegments[index] = frames
                    
                    if processedCount == times.count {
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            complete(ImagePlayerItem(frames: Array(frameSegments.joined()), duration: self.trimPosition.galleryDuration, videoAsset: self.asset))
        }
    }
    
    func destroy() {
        isDestroyed = true
        generators.forEach { $0.cancelAllCGImageGeneration() }
    }
}
