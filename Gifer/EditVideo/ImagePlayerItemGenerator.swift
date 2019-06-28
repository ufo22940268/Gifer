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
    
    lazy var generator:AVAssetImageGenerator  = {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.maximumSize = CGSize(width: 1200, height: 1200)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
        return generator
    }()
    
    var directory: URL = (try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)).appendingPathComponent("imagePlayer")
    
    internal init(avAsset: AVAsset, trimPosition: VideoTrimPosition) {
        self.asset = avAsset
        self.trimPosition = trimPosition
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
        let times = splitTimes()
        var frames = [ImagePlayerFrame]()
        initDirectory()
        generator.generateCGImagesAsynchronously(forTimes: times) { (time, image, _, _, error) in
            autoreleasepool {
                guard let image = image, error == nil else { return }
                var frame = ImagePlayerFrame(time: time - self.trimPosition.leftTrim)
                self.saveToDirectory(image: image, frame: &frame)
                frames.append(frame)
                
                if time == times.last!.timeValue {
                    complete(ImagePlayerItem(frames: frames, duration: self.trimPosition.galleryDuration))
                }
            }
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
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    }
    
    func cancel() {
        generator.cancelAllCGImageGeneration()
    }
}
