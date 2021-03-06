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
    
    static let minimunGifSize: CGSize = CGSize(width: 150, height: 150)
    
    func reduce(decreasePercent: Double = 0.1) -> GifProcessConfig? {
        var newConfig = self
        newConfig.gifSize = gifSize.applying(CGAffineTransform(scaleX: 1 - CGFloat(decreasePercent), y: 1 - CGFloat(decreasePercent)))
        if newConfig.gifSize.width < GifProcessConfig.minimunGifSize.width && newConfig.gifSize.height < GifProcessConfig.minimunGifSize.height {
            newConfig.gifSize = GifProcessConfig.minimunGifSize
        }
        return newConfig
    }
    
    func ensure(videoSize: VideoSize) -> GifProcessConfig {
        switch videoSize {
        case .auto, .large:
            return self
        case .middle:
            return self.reduce(decreasePercent: 0.2)!
        case .small:
            return self.reduce(decreasePercent: 0.4)!
        }
    }
    
    func lowestConfig(for shareType: ShareType) -> GifProcessConfig {
        var newConfig = self
        newConfig.gifSize = shareType.lowestSize
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
        var adjustFilterAppliers: [FilterApplier]?
        var stickers: [StickerInfo]
        var direction: PlayDirection
        var exportType: ShareType?
        var texts: [EditTextInfo]
        var videoSize: VideoSize = .auto
        var loopCount: LoopCount = .infinite
        
        init(start: CMTime, end: CMTime, speed: Float, cropArea: CGRect, filter: YPFilter?, stickers: [StickerInfo], direction: PlayDirection, exportType: ShareType?, texts: [EditTextInfo], adjustFilterAppliers: [FilterApplier]?) {
            self.start = start
            self.end = end
            self.speed = speed
            self.cropArea = cropArea
            self.filter = filter
            self.stickers = stickers
            self.direction = direction
            self.exportType = exportType
            self.texts = texts
            self.adjustFilterAppliers = adjustFilterAppliers
        }

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
    var playerItem: ImagePlayerItem
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
    
    init(playerItem: ImagePlayerItem, options: Options) {
        self.playerItem = playerItem
        self.options = options
        
        calculateExportConfig()
    }
    
    var shareType: ShareType {
        return options.exportType!
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
        let gifSize = shareType.initialGifSize
        processConfig = GifProcessConfig(gifSize: gifSize, extractImageCountPerSecond: extractImageCountPerSecond, gifDelayTime: gifDelayTime)
    }
    
    func calibrateSize(under memoryInMB: Double, videoSize: VideoSize, completion: @escaping (GifProcessConfig) -> Void) {
        let estimator = GifConfigCalibrator(options: options, playerItem: playerItem, processConfig: processConfig)
        estimator.calibrateSize(under: memoryInMB, completion: {(config: GifProcessConfig) in
            completion(config.ensure(videoSize: videoSize))
        })
    }
    
    static let animatedGifFilePath: URL? = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("animated.gif")
    
    var gifFilePath: URL? {
        get {
            let documentsDirectoryURL: URL? = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            return documentsDirectoryURL?.appendingPathComponent("animated.gif")
        }
    }
    
    func buildDestinationOfGif(frameCount: Int) -> CGImageDestination {
        let fileProperties: CFDictionary = [kCGImagePropertyGIFLoopCount as String: options.loopCount.count] as CFDictionary
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
        calibrateSize(under: options.exportType!.sizeLimitation, videoSize: options.videoSize) { (config) in
            self.processConfig = config
            self.generate(complete: complete)
        }
    }
    
    func generate(complete: @escaping (URL) -> Void) {
        let startProgress = options.start
        let endProgress = options.end
        let group = DispatchGroup()
        
        let generateFrames: [ImagePlayerFrame] = playerItem.getActiveFramesBetween(begin: options.start, end: options.end)
        let destination = self.buildDestinationOfGif(frameCount: generateFrames.count)
        let ciContext = CIContext(options: nil)
        
        var labelViewCaches: [LabelViewCache]! = nil
        var stickerImageCaches: [StickerImageCache]! = nil

        
        func applyFilter(_ image: CGImage, filter: YPFilter, in context: CIContext) -> CGImage {
            let ciImage = filter.applyFilter(image: CIImage(cgImage: image))
            return ciContext.createCGImage(ciImage, from: ciImage.extent)!
        }

        for (index, frame) in generateFrames.enumerated() {
            var image = frame.uiImage.resize(inSize: gifSize).cgImage!
            let interval = playerItem.frameInterval/Double(options.speed)
            let time = CMTime(seconds: Double(index)*interval, preferredTimescale: 600)
            
            let frameProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [(kCGImagePropertyGIFUnclampedDelayTime as String): interval]] as CFDictionary
            
            var ciImage = CIImage(cgImage: image)
            if let filter = self.options.filter {
                ciImage = filter.applyFilter(image: ciImage)
            }
            if let adjustFilters = self.options.adjustFilterAppliers {
                ciImage = applyFilterAppliersToImage(adjustFilters, image: ciImage)
            }
            image = ciContext.createCGImage(ciImage, from: ciImage.extent)!
            
            if labelViewCaches == nil {
                labelViewCaches = self.cacheLabelViewsForExport(image: image)
            }
            
            if stickerImageCaches == nil {
                stickerImageCaches = self.cacheStickerImageForExport(canvasSize: image.size, stickers: self.options.stickers)
            }
            
            image = self.addStickersAndTexts(current: time, image: image, cachedLabels: labelViewCaches, cachedStickers: stickerImageCaches)
            image = self.crop(image: image)

            CGImageDestinationAddImage(destination, image, frameProperties)
        }
        
        
        group.notify(queue: .global()) {
            if !CGImageDestinationFinalize(destination) {
                print("Failed to finalize  the image destination")
            }
            print("gif file \(self.gifFilePath!.path) generated")
            complete(self.gifFilePath!)
        }
    }
    
    struct LabelViewCache {
        var image: UIImage
        var rect: CGRect
        var trimPosition: VideoTrimPosition!
        
        func draw() {
            let origin = rect.center.applying(CGAffineTransform(translationX: -image.size.width/2, y: -image.size.height/2))
            self.image.draw(at: origin)
        }
    }
    
    struct StickerImageCache {
        var image: UIImage
        var rect: CGRect
        var trimPosition: VideoTrimPosition
        
        func draw() {
            image.draw(in: rect)
        }
    }
    
    func cacheLabelViewsForExport(image: CGImage) -> [LabelViewCache] {
        var caches = [LabelViewCache]()
        for textInfo in options.texts {
            let rect = textInfo.nRect!.realRect(containerSize: CGSize(width: image.width, height: image.height))
            let labelView = textInfo.createExportLabelView(imageSize: image.size, fontRect: rect)
            let labelImage = labelView.renderToImage(afterScreenUpdates: true)
            let cache = LabelViewCache(image: labelImage.rotate(by: textInfo.rotation), rect: rect, trimPosition: textInfo.trimPosition)
            caches.append(cache)
        }
        return caches
    }
    
    func cacheStickerImageForExport(canvasSize: CGSize, stickers: [StickerInfo]) -> [StickerImageCache] {
        var caches = [StickerImageCache]()
        for sticker in stickers {
            let image = sticker.image.rotate(by: sticker.rotation)
            let rect = sticker.imageFrame.applying(CGAffineTransform(scaleX: CGFloat(canvasSize.width), y: CGFloat(canvasSize.height)))
            let cache = StickerImageCache(image: image, rect: rect, trimPosition: sticker.trimPosition)
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
    
    func addStickersAndTexts(current: CMTime, image: CGImage, cachedLabels: [LabelViewCache], cachedStickers: [StickerImageCache]) -> CGImage {
        let format = UIGraphicsImageRendererFormat.init()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: image.size, format: format).image { (context) in
            UIImage(cgImage: image).draw(at: CGPoint.zero)
            
            for stickerCache in cachedStickers where stickerCache.trimPosition.contains(current) {
                stickerCache.draw()
            }
            
            for labelCache in cachedLabels where labelCache.trimPosition.contains(current) {
                labelCache.draw()
            }
        }
        return image.cgImage!
    }
}
