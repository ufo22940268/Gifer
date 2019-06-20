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
import AVKit

class GiferTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
        
    func buildDestinationOfGif(frameCount: Int) -> CGImageDestination {
        let fileProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]]  as CFDictionary
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

    
//    func testParseVideo() {
//        let expect = expectation(description: "parse video")
//        let video = getTestVideo()
//        PHImageManager.default().requestAVAsset(forVideo: video, options: nil) { (asset, _, _) in
//            let start = CGFloat(0.0)
//            let end = CGFloat(1.0)
//            GifGenerator(video: asset!).run(start: start, end: end) { _ in
//                expect.fulfill()
//            }
//        }
//        wait(for: [expect], timeout: 1000*10)
//    }
    
    func testExtractVideoThumbernails() {
        let expect = expectation(description: "testExtractVideoThumbernails")
        let asset = getTestVideo()
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { (playerItem, info) in
            let thumernails = playerItem!.asset.extractThumbernails()
            assert(thumernails.count > 0)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 10)
    }
    
    
    func testVideoComposition() {
        
        let asset = PHAsset.fetchAssets(with: .video, options: nil).object(at: 0)
        let exp = expectation(description: "export sucess")
        PHImageManager.default().requestAVAsset(forVideo: asset, options: nil) { (videoAsset, _, _) in
            guard let videoAsset = videoAsset else { return }
            
            let ciContext = CIContext(eaglContext: EAGLContext(api: EAGLRenderingAPI.openGLES3)!)
            let composition = AVVideoComposition(asset: videoAsset) { (request) in

                let outputImage = request.sourceImage.clampedToExtent().applyingFilter("CIGaussianBlur").cropped(to: request.sourceImage.extent)
                request.finish(with: outputImage, context: ciContext)
                
            }
            
            let export = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPreset640x480)!
            export.videoComposition = composition
            export.outputFileType = .m4v
            export.outputURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("a.m4v")
            
            let fileManager = FileManager.default
            try? fileManager.removeItem(at: export.outputURL!)
            
            DispatchQueue.global().async {
                export.exportAsynchronously {
                    print("success \(String(describing: export.error)) \(export.status.rawValue)")
                    exp.fulfill()
                }
            }
        }
        
        
        wait(for: [exp], timeout: 200)
    }
    
    func testReduceVideoFrameRate() {
        let phAsset = PHAsset.fetchAssets(with: .video, options: nil).object(at: 0)
        let exp = expectation(description: "export sucess")
        
        PHImageManager.default().requestAVAsset(forVideo: phAsset, options: nil) { (videoAsset, _, _) in
            VideoCache(asset: videoAsset!).parse {video in
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 40)
    }
    
    
    func testAssetExport() {
        let phAsset = PHAsset.fetchAssets(with: .video, options: nil).object(at: 0)
        let exp = expectation(description: "export sucess")
        PHImageManager.default().requestAVAsset(forVideo: phAsset, options: nil) { (videoAsset, _, _) in
            let session = AVAssetExportSession(asset: videoAsset!, presetName: AVAssetExportPresetMediumQuality)!
            session.outputURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("k.mov")
            session.outputFileType = AVFileType.mov
            try? FileManager.default.removeItem(at: session.outputURL!)
            session.exportAsynchronously {
                exp.fulfill()
            }
        }
        
        
        wait(for: [exp], timeout: 10)
    }
    
    func composeBetween(_ rawImage: CIImage, _ filterImage: CIImage, percent: Double) -> CIImage {
        return rawImage.applyingFilter("CIDissolveTransition", parameters: ["inputTargetImage": filterImage, "inputTime": percent])
    }
    
    func testCompositeFilters() {
        let rawImage = CIImage(image: #imageLiteral(resourceName: "RRMJ6240.JPG"))!
        let filterImage = rawImage.applyingFilter("CIPhotoEffectChrome")
        
        _ = composeBetween(rawImage, filterImage, percent: 0.2)
    }
    
    func testFonts() {
        let fonts = UIFont.listAllFonts()
        print(fonts.map {$0.fontName})
    }
}
