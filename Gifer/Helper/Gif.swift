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
        generator.appliesPreferredTrackTransform = true
        for i in 0..<imageCount {
            let time = CMTime(value: CMTimeValue(Double(self.duration.value)/Double(imageCount)*Double(i)), timescale: 600)
            let cgImage = (try! generator.copyCGImage(at: time, actualTime: nil)).thumbernail()
            images.append(UIImage(cgImage: cgImage))
        }
        return images
    }
    
    func extractThumbernail(on time: CMTime) -> UIImage {
        let generator = AVAssetImageGenerator(asset: self)
        generator.appliesPreferredTrackTransform = true
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
        var stickers: [StickerInfo]
        var direction: PlayDirection
        var exportType: ShareType?
        var texts: [EditTextInfo]

        static func == (lhs: GifGenerator.Options, rhs: GifGenerator.Options) -> Bool {
            return lhs.start.seconds == rhs.start.seconds
            && lhs.end.seconds == rhs.end.seconds
            && lhs.speed == rhs.speed
            && lhs.cropArea == rhs.cropArea
        }
        
        var duration: CMTime {
            return end - start
        }
    }
    
    let fileName = "animated.gif"
    var videoAsset: AVAsset
    var options: Options
    var gifSize: CGSize!
    private var extractedImageCountPerSecond: Int!
    private var gifDelayTime: Float!
    
    init(video: AVAsset, options: Options) {
        self.videoAsset = video
        self.options = options
        
        calculateExportConfig()
    }
    
    func calculateExportConfig() {
        var defaultCount:Int
        if options.speed < 1 {
            defaultCount = 4
        } else {
            defaultCount = 7
        }
        extractedImageCountPerSecond = Int(Float(defaultCount)/options.speed)
        gifDelayTime = 1/Float(defaultCount)
        let size = options.exportType!.gifSize
        gifSize = CGSize(width: size, height: size)
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
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = gifSize
        generator.requestedTimeToleranceAfter = CMTime.zero
        generator.requestedTimeToleranceBefore = CMTime.zero
        let ciContext = CIContext(options: nil)
        times = arrangeTimeByPlayDirection(times)
        
        var labelViewCaches: [LabelViewCache]! = nil
        var stickerImageCaches: [StickerImageCache]! = nil
        
        generator.generateCGImagesAsynchronously(forTimes: times, completionHandler: { (requestTime, image, actualTime, result, error) in
            guard var image = image else { return }
            
            let frameProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [(kCGImagePropertyGIFUnclampedDelayTime as String): self.gifDelayTime]] as CFDictionary
            
            let originImageSize = image.size
            image = self.crop(image: image)
            if let filter = self.options.filter {
                image = applyFilter(image, filter: filter, in: ciContext)
            }
            
            DispatchQueue.main.sync {
                if labelViewCaches == nil {
                    labelViewCaches = self.cacheLabelViewsForExport(image: image)
                }
            
                if stickerImageCaches == nil {
                    stickerImageCaches = self.cacheStickerImageForExport(canvasSize: originImageSize, stickers: self.options.stickers)
                }
            }
            
            image = self.addStickersAndTexts(image: image, cachedLabels: labelViewCaches, cachedStickers: stickerImageCaches)
            
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
    
    struct LabelViewCache {
        var image: UIImage
        var rect: CGRect
        
        func draw() {
            self.image.draw(at: rect.origin)
        }
    }
    
    struct StickerImageCache {
        var image: UIImage
        var rect: CGRect
        
        func draw() {
            image.draw(in: rect)
        }
    }
    
    func cacheLabelViewsForExport(image: CGImage) -> [LabelViewCache] {
        var caches = [LabelViewCache]()
        for textInfo in options.texts {
            let labelView = textInfo.createExportLabelView(imageSize: image.size)
            let rect = textInfo.nRect!.realRect(containerSize: CGSize(width: image.width, height: image.height))
            let cache = LabelViewCache(image: labelView.renderToImage(afterScreenUpdates: true).rotate(by: textInfo.rotation), rect: rect)
            caches.append(cache)
        }
        return caches
    }
    
    func cacheStickerImageForExport(canvasSize: CGSize, stickers: [StickerInfo]) -> [StickerImageCache] {
        var caches = [StickerImageCache]()
        for sticker in stickers {
            let image = sticker.image.rotate(by: sticker.rotation)
            let rect = sticker.imageFrame.applying(CGAffineTransform(scaleX: CGFloat(canvasSize.width), y: CGFloat(canvasSize.height)))
            let cache = StickerImageCache(image: image, rect: rect)
            caches.append(cache)
        }
        return caches
    }
    
    func arrangeTimeByPlayDirection(_ times: [NSValue]) -> [NSValue] {
        switch options.direction {
        case .forward:
            return times
        case .backward:
            return times.reversed()
        }
    }
    
    func crop(image: CGImage) -> CGImage {
        let rect = options.cropArea.applying(CGAffineTransform(scaleX: CGFloat(image.width), y: CGFloat(image.height)))
        return image.cropping(to: rect)!
    }
    
    func addStickersAndTexts(image: CGImage, cachedLabels: [LabelViewCache], cachedStickers: [StickerImageCache]) -> CGImage {
        let image = UIGraphicsImageRenderer(size: CGSize(width: image.width, height: image.height)).image { (context) in
            UIImage(cgImage: image).draw(at: CGPoint.zero)
            
            for stickerCache in cachedStickers {
                stickerCache.draw()
            }
            
            for (index, _) in options.texts.enumerated() {
                let labelCache = cachedLabels[index]
                labelCache.draw()
            }
        }
        return image.cgImage!
    }
}
