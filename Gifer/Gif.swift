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

extension UIImage {
    func rotate(by radian: CGFloat) -> UIImage {
        //Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        let t: CGAffineTransform = CGAffineTransform(rotationAngle: radian)
        rotatedViewBox.transform = t
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        //Create the bitmap context 
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (radian))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(self.cgImage!, in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
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
    
    struct Options: Equatable {
        var start: CMTime
        var end: CMTime
        var speed: Float
        var cropArea: CGRect
        var filter: YPFilter?
        var stickers: [Sticker]

        static func == (lhs: GifGenerator.Options, rhs: GifGenerator.Options) -> Bool {
            return lhs.start.seconds == rhs.start.seconds
            && lhs.end.seconds == rhs.end.seconds
            && lhs.speed == rhs.speed
            && lhs.cropArea == rhs.cropArea
        }
        
    }
    
    let fileName = "animated.gif"
    var videoAsset: AVAsset
    var options: Options
    
    init(video: AVAsset, options: Options) {
        self.videoAsset = video
        self.options = options
      
        let defaultCount = 10
        extractedImageCountPerSecond = Int(Float(defaultCount)/options.speed)
        gifDelayTime = 0.1
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
    
    enum GifSize: Int, RawRepresentable {
        case middle = 250
    }
    
    func run(complete: @escaping (URL) -> Void) {
        let startProgress = options.start
        let endProgress = options.end
        var times = [NSValue]()
        let group = DispatchGroup()
        var currentTime = startProgress
        while currentTime < endProgress {
            times.append(NSValue(time: currentTime))
            currentTime = currentTime + CMTime(seconds: 1/Double(extractedImageCountPerSecond), preferredTimescale: currentTime.timescale)
            group.enter()
        }
        
        let destination = self.buildDestinationOfGif(frameCount: times.count)
        let generator = AVAssetImageGenerator(asset: videoAsset)
        let gifSize = GifSize.middle
        generator.maximumSize = CGSize(width: gifSize.rawValue, height: gifSize.rawValue)
        generator.requestedTimeToleranceAfter = CMTime.zero
        generator.requestedTimeToleranceBefore = CMTime.zero
        let ciContext = CIContext(options: nil)
        generator.generateCGImagesAsynchronously(forTimes: times, completionHandler: { (requestTime, image, actualTime, result, error) in
            guard var image = image else { return }
            let frameProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [(kCGImagePropertyGIFUnclampedDelayTime as String): self.gifDelayTime]] as CFDictionary
            image = self.crop(image: image)
            if let filter = self.options.filter {
                image = applyFilter(image, filter: filter, in: ciContext)
            }
            image = self.addSticker(image: image)
            CGImageDestinationAddImage(destination, image, frameProperties)
            group.leave()
        })
        
        func applyFilter(_ image: CGImage, filter: YPFilter, in context: CIContext) -> CGImage {
            guard let applier = filter.applier else { return image }
            let ciImage = applier(CIImage(cgImage: image))!
            return ciContext.createCGImage(ciImage, from: ciImage.extent)!
        }
        
        
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
    
    func addSticker(image: CGImage) -> CGImage {
        
        let image = UIGraphicsImageRenderer(size: CGSize(width: image.width, height: image.height)).image { (context) in
            UIImage(cgImage: image).draw(at: CGPoint.zero)
            for sticker in options.stickers {
                sticker.image.rotate(by: sticker.rotation!).draw(in: sticker.imageFrame!.applying(CGAffineTransform(scaleX: CGFloat(image.width), y: CGFloat(image.height))))
            }
        }
        return image.cgImage!
    }
    
}
