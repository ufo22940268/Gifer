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
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let img1 = #imageLiteral(resourceName: "IMG_0009.PNG")
        let img2 = #imageLiteral(resourceName: "IMG_0010.PNG")
        
        let temporaryFile = (NSTemporaryDirectory() as NSString).appendingPathComponent("test.gif")
        let fileURL = URL(fileURLWithPath: temporaryFile)
        let destination  = CGImageDestinationCreateWithURL(fileURL as CFURL, kUTTypeGIF, 2, nil)!
        let frameProperties = [
            kCGImagePropertyGIFDictionary as String:[
                kCGImagePropertyGIFDelayTime as String:1
            ]
        ]
        CGImageDestinationAddImage(destination, img1.cgImage!, frameProperties as CFDictionary)
        
        let fileProperties = [kCGImagePropertyGIFDictionary as String:[
            kCGImagePropertyGIFLoopCount as String: NSNumber(value: Int32(10) as Int32)],
                              kCGImagePropertyGIFHasGlobalColorMap as String: NSValue(nonretainedObject: true)
            ] as [String : Any]
        CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)
        
        CGImageDestinationFinalize(destination)
    }
}
