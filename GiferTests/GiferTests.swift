//
//  GiferTests.swift
//  GiferTests
//
//  Created by Frank Cheng on 2018/11/8.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import XCTest
@testable import Gifer
import UIKit
import ImageIO
import MobileCoreServices
import Photos


extension UIImage {
    static func animatedGif(from images: [UIImage]) {
        let fileProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]]  as CFDictionary
        let frameProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [(kCGImagePropertyGIFDelayTime as String): 1.0]] as CFDictionary
        
        let documentsDirectoryURL: URL? = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL: URL? = documentsDirectoryURL?.appendingPathComponent("animated.gif")
        
        if let url = fileURL as CFURL? {
            if let destination = CGImageDestinationCreateWithURL(url, kUTTypeGIF, images.count, nil) {
                CGImageDestinationSetProperties(destination, fileProperties)
                for image in images {
                    if let cgImage = image.cgImage {
                        CGImageDestinationAddImage(destination, cgImage, frameProperties)
                    }
                }
                if !CGImageDestinationFinalize(destination) {
                    print("Failed to finalize the image destination")
                }
                print("Url = \(fileURL)")
            }
        }
    }
}

class GiferTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testGenerateGif() {
        let img1 = #imageLiteral(resourceName: "IMG_0009.PNG")
        let img2 = #imageLiteral(resourceName: "IMG_0010.PNG")
        UIImage.animatedGif(from: [img1, img2])
    }
    
    func getTestVideo() -> PHAsset {
        let asset = PHAsset.fetchAssets(with: .video, options: nil).firstObject!
        return asset
    }
    
    func buildDestinationOfGif(frameCount: Int) -> CGImageDestination {
        let fileProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]]  as CFDictionary
        let frameProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [(kCGImagePropertyGIFDelayTime as String): 1.0]] as CFDictionary
        
        let documentsDirectoryURL: URL? = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL: URL? = documentsDirectoryURL?.appendingPathComponent("animated.gif")
        
        if let url = fileURL as CFURL? {
            if let destination = CGImageDestinationCreateWithURL(url, kUTTypeGIF, frameCount, nil) {
                CGImageDestinationSetProperties(destination, fileProperties)
                return destination
            }
        }
        
        fatalError()
    }

    
    func testParseVideo() {
        let expect = expectation(description: "parse video")
        let video = getTestVideo()
        let manager = PHImageManager.default()
        print("video: \(video)")
        manager.requestAVAsset(forVideo: video, options: nil) { (avAsset, _, info) in
            if let avAsset = avAsset {
                print("requestAVAsset \(avAsset) \(info)")
                var times = [NSValue]()
                let frameCounts: Int = Int(avAsset.duration.seconds)
                let group = DispatchGroup()
                for second in 0..<frameCounts {
                    times.append(NSValue(time: CMTimeMakeWithSeconds(Float64(second), preferredTimescale: 1)))
                    group.enter()
                }
                let destination = self.buildDestinationOfGif(frameCount: Int(avAsset.duration.seconds))
                try! AVAssetImageGenerator(asset: avAsset).generateCGImagesAsynchronously(forTimes: times, completionHandler: { (_, image, _, _, error) in
                    let frameProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [(kCGImagePropertyGIFDelayTime as String): 1.0]] as CFDictionary
                    CGImageDestinationAddImage(destination, image!, frameProperties)
                    group.leave()
                })
                
                
                group.notify(queue: .global()) {
                    if !CGImageDestinationFinalize(destination) {
                        print("Failed to finalize the image destination")
                    }
                    print("finish")
                }
            }
        }
        
        wait(for: [expect], timeout: 1000*20)
    }
}
