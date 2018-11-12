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
        GifGenerator(video: video).run {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1000*10)
    }
}
