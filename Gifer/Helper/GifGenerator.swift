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
        
        let render = UIGraphicsImageRenderer(bounds: CGRect(origin: .zero, size: rotatedSize))
        let newImage = render.image { context in
            let bitmap: CGContext = context.cgContext
            //Move the origin to the middle of the image so we will rotate and scale around the center.
            bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            //Rotate the image context
            bitmap.rotate(by: (radian))
            //Now, draw the rotated/scaled image into the context
            bitmap.scaleBy(x: 1.0, y: -1.0)
            bitmap.draw(self.cgImage!, in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))
        }
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

struct GifProcessConfig {
    var gifSize: CGSize
    var extractImageCountPerSecond: Int
    var gifDelayTime: Double
    
    func reduce() -> GifProcessConfig {
        let decreasePercent = 0.1
        var newConfig = self
        newConfig.gifSize = gifSize.applying(CGAffineTransform(scaleX: 1 - CGFloat(decreasePercent), y: 1 - CGFloat(decreasePercent)))
        return newConfig
    }
    
    var lowestConfig: GifProcessConfig {
        var newConfig = self
        newConfig.gifSize = CGSize(width: 200, height: 200)
        return newConfig
    }
}

public class GifGenerator {
    
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
        
        func splitVideo(extractedImageCountPerSecond: Int) -> [CMTime] {
            var currentTime = start
            var times = [CMTime]()
            while currentTime < end {
                times.append(currentTime)
                currentTime = currentTime + CMTime(seconds: 1/Double(extractedImageCountPerSecond), preferredTimescale: currentTime.timescale)
            }
            return times
        }

        var duration: CMTime {
            return end - start
        }
    }
    
    let fileName = "animated.gif"
    var videoAsset: AVAsset
    var options: Options
    var gifSize: CGSize! {
        return processConfig.gifSize
    }
    private var extractImageCountPerSecond: Int! {
        return processConfig.extractImageCountPerSecond
    }
    var gifDelayTime: Double! {
        return processConfig.gifDelayTime
    }
    
    var processConfig: GifProcessConfig!
    
    init(video: AVAsset, options: Options) {
        self.videoAsset = video
        self.options = options
        
        calculateExportConfig()
    }
    
    func calculateExportConfig() {
        var gifImageCountPerSecond:Int
        if options.speed < 1 {
            gifImageCountPerSecond = 4
        } else {
            gifImageCountPerSecond = 7
        }
        let extractImageCountPerSecond = Int(Float(gifImageCountPerSecond)/options.speed)
        let gifDelayTime = 1/Double(gifImageCountPerSecond)
        let size = options.exportType!.gifSize(duration: options.duration)
        let gifSize = CGSize(width: size, height: size)
        processConfig = GifProcessConfig(gifSize: gifSize, extractImageCountPerSecond: extractImageCountPerSecond, gifDelayTime: gifDelayTime)
    }
    
    func calibrateSize(under memoryInMB: Double, completion: @escaping (GifProcessConfig) -> Void) {
        let estimator = GifConfigCalibrator(options: options, asset: videoAsset, processConfig: processConfig)
        estimator.calibrateSize(under: memoryInMB, completion: completion)
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
        calibrateSize(under: options.exportType!.sizeLimitation) { (config) in
            self.processConfig = config
            self.generateGif(complete: complete)
        }
    }

    
    func generateGif(complete: @escaping (URL) -> Void) {
        let startProgress = options.start
        let endProgress = options.end
        var times = [NSValue]()
        let group = DispatchGroup()
        var currentTime = startProgress
        while currentTime < endProgress {
            times.append(NSValue(time: currentTime))
            currentTime = currentTime + CMTime(seconds: 1/Double(extractImageCountPerSecond), preferredTimescale: currentTime.timescale)
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
            let origin = rect.center.applying(CGAffineTransform(translationX: -image.size.width/2, y: -image.size.height/2))
            self.image.draw(at: origin)
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
            let labelImage = labelView.renderToImage(afterScreenUpdates: true)
            let cache = LabelViewCache(image: labelImage.rotate(by: textInfo.rotation), rect: rect)
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
        let format = UIGraphicsImageRendererFormat.init()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: image.size, format: format).image { (context) in
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
