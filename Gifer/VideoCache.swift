//
//  VideoCache.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/18.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class VideoCache {
    
    var asset: AVAsset!
    var images: [UIImage]?
    var preferredImageInterval = CMTime(seconds: 0.1, preferredTimescale: 600)
    var imageInterval: CMTime?
    let tempFilePath: URL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("k.mov")
    
    init(asset: AVAsset) {
        self.asset = asset
    }
    
    typealias ParseHandler = (_ video: URL) -> Void
    
    func parse(completion: @escaping ParseHandler) {
        generateImages(for: self.asset)
        composeVideo(with: self.images!, completion: completion)
    }
    
    private func generateImages(for videoAsset: AVAsset) {
        let generator = AVAssetImageGenerator(asset: videoAsset)
        generator.maximumSize = CGSize(width: 300, height: 300)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
//        let totalDuration = videoAsset.duration
        let totalDuration = CMTime(seconds: 3, preferredTimescale: 600)
        let extractImageCount = Int(totalDuration.seconds/preferredImageInterval.seconds) + 1
        let interval = CMTimeMultiplyByFloat64(totalDuration, multiplier: 1/Double(extractImageCount))
        self.imageInterval = interval
        
        var images = [UIImage]()
        for index in 0..<extractImageCount {
            let time = CMTimeMultiply(interval, multiplier: Int32(index))
            let actualtime = UnsafeMutablePointer<CMTime>.allocate(capacity: 1)
            actualtime.initialize(to: time)
            let cgImage = try! generator.copyCGImage(at: time, actualTime: actualtime)
            actualtime.deallocate()
            images.append(UIImage(cgImage: cgImage))
        }
        self.images = images
    }
    
    private func composeVideo(with images: [UIImage], completion: @escaping ParseHandler) {

        try? FileManager.default.removeItem(at: tempFilePath)
        let writer = try! AVAssetWriter(url: tempFilePath, fileType: AVFileType.mov)
        let writerInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: nil)
        
        writer.add(writerInput)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)
        writer.startWriting()
        writer.startSession(atSourceTime: CMTime.zero)
        writerInput.requestMediaDataWhenReady(on: DispatchQueue(label: "asdf"), using: {
            images.enumerated().forEach({ args in
                if writerInput.isReadyForMoreMediaData {
                    let (index, image) = args
                    let presentTime: CMTime = CMTime(seconds: self.imageInterval!.seconds*Double(index), preferredTimescale: 600)
                    adaptor.append(image.toPixelBuffer()!, withPresentationTime: presentTime)
                }
            })
            writerInput.markAsFinished()
            writer.finishWriting {
                completion(self.tempFilePath)
            }
        })
    }
}


extension UIImage {
    func toPixelBuffer() -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(self.size.width), Int(self.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}
