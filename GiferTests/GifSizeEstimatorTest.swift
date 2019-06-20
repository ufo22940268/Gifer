//
//  GifSizeEstimatorTest.swift
//  GiferTests
//
//  Created by Frank Cheng on 2019/4/15.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import XCTest
import Photos
@testable import Gifer

class GifSizeEstimatorTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    private func loadTestVideo(complete: @escaping (AVAsset) -> Void) {
        let phAsset = PHAsset.fetchAssets(with: .video, options: nil).object(at: 0)
        PHImageManager.default().requestAVAsset(forVideo: phAsset, options: nil) { (videoAsset, _, _) in
            complete(videoAsset!)
        }
    }

//    func testEstimateSize() {
//        let exp = expectation(description: "estimate sucess")
//        loadTestVideo { (asset) in
//            print(asset)
//            let options = GifGenerator.Options(start: CMTime(seconds: 0, preferredTimescale: asset.duration.timescale), end: asset.duration, speed: 1, cropArea: CGRect(origin: .zero, size: CGSize(width: 1, height: 1)), filter: nil, stickers: [], direction: .forward, exportType: .photo, texts: [])
//            let generator = GifGenerator(video: asset, options: options)
//            generator.calibrateSize(under: 5) { newConfig in
//                exp.fulfill()
//            }
//        }
//        
//        wait(for: [exp], timeout: 10)
//    }
    
}
