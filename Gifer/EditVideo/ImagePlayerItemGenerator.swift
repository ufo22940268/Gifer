//
//  ImagePlayerItem.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/26.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import AVKit
import UIKit

class ImagePlayerItemGenerator {
    
    var asset: AVAsset
    var trimPosition: VideoTrimPosition
    var isDestroyed = false
    
    let generatorParallelNumber: Int = 4
    
    lazy var generators:[AVAssetImageGenerator]  = {
        return (0..<self.generatorParallelNumber).map { _ in
            return createAssetGenerator()
        }
    }()
    
    var directory: URL = (try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)).appendingPathComponent("imagePlayer")
    
    internal init(avAsset: AVAsset, trimPosition: VideoTrimPosition) {
        self.asset = avAsset
        self.trimPosition = trimPosition
    }
    
    func createAssetGenerator() -> AVAssetImageGenerator {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.maximumSize = CGSize(width: 1200, height: 1200)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
        return generator
    }
    
    func splitTimes() -> [NSValue] {
        var t = trimPosition.leftTrim
        let interval = CMTime(seconds: 0.2, preferredTimescale: 600)
        var ar = [NSValue]()
        while t + interval < trimPosition.rightTrim {
            t = t + interval
            ar.append(NSValue(time: t))
        }

        if ar.last!.timeValue != trimPosition.rightTrim {
            ar[ar.count - 1] = NSValue(time: trimPosition.rightTrim)
        }
        
        return ar
    }
    
    func extract(complete: @escaping (ImagePlayerItem) -> Void) {
        let began = Date()
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
        
        initDirectory()
        
        let group = DispatchGroup()
        var size: CGSize!
        for index in 0..<generatorParallelNumber {
            group.enter()
            let times = timeSegments[index]
            generators[index].generateCGImagesAsynchronously(forTimes: times) { (time, image, _, result, error) in
                autoreleasepool {
                    guard let image = image, error == nil, result == .succeeded, !self.isDestroyed else { return }
                    if size == nil {
                        size = image.size
                    }
                    var frames = frameSegments[index]
                    var frame = ImagePlayerFrame(time: time - self.trimPosition.leftTrim)
                    self.saveToDirectory(image: image, frame: &frame)
                    frames.append(frame)
                    frameSegments[index] = frames
                    
                    if time == times.last!.timeValue {
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            print(Date().timeIntervalSince(began))
            complete(ImagePlayerItem(frames: Array(frameSegments.joined()), duration: self.trimPosition.galleryDuration, size: size))
        }
    }
    
    func saveToDirectory(image: CGImage, frame: inout ImagePlayerFrame) {
        let filePath = directory.appendingPathComponent(frame.time.seconds.description)
        do {
            try UIImage(cgImage: image).jpegData(compressionQuality: 1)?.write(to: filePath)
            frame.path = filePath
        } catch {
            print("error: \(error)")
        }
    }
    
    func initDirectory() {
        try? FileManager.default.removeItem(at: directory)
        try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    }
    
    func destroy() {
        isDestroyed = true
        generators.forEach { $0.cancelAllCGImageGeneration() }
    }
}
