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

extension CGImage {
    func thumbernail() -> CGImage {
        let cgData = UIImage(cgImage: self).pngData()
        let source = CGImageSourceCreateWithData(cgData! as CFData, nil)!
        return CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 200] as CFDictionary)!
    }
}

extension AVAsset {
    
    @available(*, deprecated)
    func extractThumbernails() -> [UIImage] {
        var images = [UIImage]()

        let imageCount = 20
        let generator = AVAssetImageGenerator(asset: self)
        for i in 0..<imageCount {
            let time = CMTime(value: CMTimeValue(Double(self.duration.value)/Double(imageCount)*Double(i)), timescale: 600)
            let cgImage = (try! generator.copyCGImage(at: time, actualTime: nil)).thumbernail()
            images.append(UIImage(cgImage: cgImage))
        }
        return images
    }
    
    func extractThumbernail(on time: CMTime) -> UIImage {
        let generator = AVAssetImageGenerator(asset: self)
        let cgImage = try! generator.copyCGImage(at: time, actualTime: nil)
        return UIImage(cgImage: cgImage)
    }    
}

class GifGenerator {
    
    struct Options {
        var start: CMTime
        var end: CMTime
        var speed: Float
        var cropArea: CGRect
    }
    
    let fileName = "animated.gif"
    var videoAsset: AVAsset
    var options: Options
    
    init(video: AVAsset, options: Options) {
        self.videoAsset = video
        self.options = options
      
        let defaultCount = 10
        extractedImageCountPerSecond = defaultCount
        let normalDelay = 1/Float(extractedImageCountPerSecond)
        gifDelayTime = normalDelay/options.speed
    }
    
    var gifFilePath: URL? {
        get {
            let documentsDirectoryURL: URL? = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            return documentsDirectoryURL?.appendingPathComponent("animated.gif")
        }
    }
    
    func buildDestinationOfGif(frameCount: Int) -> CGImageDestination {
        let fileProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]]  as CFDictionary
        let fileURL: URL? = gifFilePath
        
        if let url = fileURL as CFURL? {
            if let destination = CGImageDestinationCreateWithURL(url, kUTTypeGIF, frameCount, nil) {
                CGImageDestinationSetProperties(destination, fileProperties)
                return destination
            }
        }
        
        fatalError()
    }
    
    private var extractedImageCountPerSecond: Int
    private let gifDelayTime: Float
    
    func calGifFrameCount(start: CMTime, end: CMTime) -> Int {
        return Int(Double(end.value - start.value)/(600/Double(extractedImageCountPerSecond)))
    }

    enum GifSize: Int, RawRepresentable {
        case middle = 500
    }
    
    func run(complete: @escaping (URL) -> Void) {
        let startProgress = options.start
        let endProgress = options.end
        var times = [NSValue]()
        let group = DispatchGroup()
        let gifFrameCount = calGifFrameCount(start: startProgress, end: endProgress)
        let frameRangeOfSingleImage = CGFloat(endProgress.value - startProgress.value)/CGFloat(gifFrameCount)
        for index in 0..<gifFrameCount {
            let time = CMTime(value: CMTimeValue(Double(startProgress.value) + Double(index)*Double(frameRangeOfSingleImage)), timescale: 600)
            times.append(NSValue(time: time))
            group.enter()
        }
        let destination = self.buildDestinationOfGif(frameCount: gifFrameCount)
        let generator = AVAssetImageGenerator(asset: videoAsset)
        let gifSize = GifSize.middle
        generator.maximumSize = CGSize(width: gifSize.rawValue, height: gifSize.rawValue)
        generator.requestedTimeToleranceAfter = CMTime.zero
        generator.requestedTimeToleranceBefore = CMTime.zero
        generator.generateCGImagesAsynchronously(forTimes: times, completionHandler: { (requestTime, image, actualTime, result, error) in
            guard var image = image else { return }
            let frameProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [(kCGImagePropertyGIFUnclampedDelayTime as String): self.gifDelayTime]] as CFDictionary
            image = self.crop(image: image)
            CGImageDestinationAddImage(destination, image, frameProperties)
            group.leave()
        })
        
        
        group.notify(queue: .global()) {
            if !CGImageDestinationFinalize(destination) {
                print("Failed to finalize the image destination")
            }
            print("gif file \(self.gifFilePath!.path) generated")
            complete(self.gifFilePath!)
        }
    }
    
    func crop(image: CGImage) -> CGImage {
        let rect = options.cropArea.applying(CGAffineTransform(scaleX: CGFloat(image.width), y: CGFloat(image.height)))
        return image.cropping(to: rect)!
    }
}
