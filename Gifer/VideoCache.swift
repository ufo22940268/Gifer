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
    let tempFilePath: URL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("k.mov")
    
    init(asset: AVAsset) {
        self.asset = asset
    }
    
    typealias ParseHandler = (_ video: URL) -> Void
    
    func parse(completion: @escaping ParseHandler) {
        DispatchQueue.global().async {
            let session = AVAssetExportSession(asset: self.asset, presetName: AVAssetExportPresetMediumQuality)!
            try? FileManager.default.removeItem(at: self.tempFilePath)
            session.outputURL = self.tempFilePath
            session.outputFileType = AVFileType.mov
            session.exportAsynchronously {
                DispatchQueue.main.async {
                    completion(session.outputURL!)
                }
            }
        }
    }
}
