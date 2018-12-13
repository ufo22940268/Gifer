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

    
    func testParseVideo() {
        let expect = expectation(description: "parse video")
        let video = getTestVideo()
        PHImageManager.default().requestAVAsset(forVideo: video, options: nil) { (asset, _, _) in
            let start = CGFloat(0.0)
            let end = CGFloat(0.5)
            GifGenerator(video: asset!).run(start: start, end: end) {
                expect.fulfill()
            }
        }
        wait(for: [expect], timeout: 1000*10)
    }
    
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
}

