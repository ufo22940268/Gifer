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
    
    let fileName = "animated.gif"
    var videoAsset: AVAsset
    
    init(video: AVAsset) {
        self.videoAsset = video
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
    
    private let extractedImageCountPerSecond = 10
    
    func calGifFrameCount(start: CGFloat, end: CGFloat) -> Int {
        return Int((end - start)/(600/CGFloat(extractedImageCountPerSecond)))
    }

    enum GifSize: Int, RawRepresentable {
        case middle = 500
    }
    
    func run(start startProgress: CGFloat, end endProgress: CGFloat, complete: @escaping (URL) -> Void) {
        var times = [NSValue]()
        let startFrame = CGFloat(videoAsset.duration.value)*startProgress
        let endFrame = CGFloat(videoAsset.duration.value)*endProgress
        let group = DispatchGroup()
        let gifFrameCount = calGifFrameCount(start: startFrame, end: endFrame)
        let frameRangeOfSingleImage = (endFrame - startFrame)/CGFloat(gifFrameCount)
        for index in 0..<gifFrameCount {
            let time = CMTime(value: CMTimeValue(Double(startFrame) + Double(index)*Double(frameRangeOfSingleImage)), timescale: 600)
            times.append(NSValue(time: time))
            group.enter()
        }
        let destination = self.buildDestinationOfGif(frameCount: gifFrameCount)
        let generator = AVAssetImageGenerator(asset: videoAsset)
        let gifSize = GifSize.middle
        generator.maximumSize = CGSize(width: gifSize.rawValue, height: gifSize.rawValue)
        generator.requestedTimeToleranceAfter = CMTime.zero
        generator.requestedTimeToleranceBefore = CMTime.zero
        generator.generateCGImagesAsynchronously(forTimes: times, completionHandler: { (requestTime, image, actualTime, _, error) in
            let frameProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [(kCGImagePropertyGIFDelayTime as String): 0.1]] as CFDictionary
            CGImageDestinationAddImage(destination, image!, frameProperties)
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
}
