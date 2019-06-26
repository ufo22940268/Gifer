//
//  ImagePlayerItem.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/26.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import AVKit
import UIKit

struct ImagePlayerFrame {
    var image: CGImage
    var time: CMTime
    var path: URL?
    
    init(image: CGImage, time: CMTime) {
        self.image = image
        self.time = time
    }
    
    mutating func save(to directory: URL) {
        let filePath = directory.appendingPathComponent(time.seconds.description)
        do {
            try UIImage(cgImage: image).jpegData(compressionQuality: 0.7)?.write(to: filePath)
        } catch {
            print("error: \(error)")
        }
    }
}

class ImagePlayerItem {
    
    var asset: AVAsset
    lazy var generator:AVAssetImageGenerator  = {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.maximumSize = CGSize(width: 800, height: 800)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
        return generator
    }()
    
    var directory: URL = (try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)).appendingPathComponent("imagePlayer")
    
    internal init(avAsset: AVAsset) {
        self.asset = avAsset
    }
    
    func splitTimes(duration: CMTime) -> [NSValue] {
        var t = CMTime.zero
        let interval = CMTime(seconds: 0.3, preferredTimescale: 600)
        var ar = [NSValue]()
        while t + interval < duration {
            t = t + interval
            ar.append(NSValue(time: t))
        }
        return ar
    }
    
    func extract(complete: @escaping () -> Void) {
        let times = splitTimes(duration: asset.duration)
        var result = [ImagePlayerFrame]()
        generator.generateCGImagesAsynchronously(forTimes: times) { (time, image, _, _, error) in
            guard let image = image, error == nil else { return }
            result.append(ImagePlayerFrame(image: image, time: time))
            if time == times.last!.timeValue {
                print(result)
                self.saveToDirectory(&result, complete: complete)
            }
        }
    }
    
    func saveToDirectory(_ result: inout [ImagePlayerFrame], complete: @escaping () -> Void) {
        initDirectory()
        for (index, frame) in result.enumerated() {
            var newFrame = frame
            newFrame.save(to: directory)
            result[index] = newFrame
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
