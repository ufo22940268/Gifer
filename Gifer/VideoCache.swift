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

protocol VideoCacheDelegate: class {
    func onParsingProgressChanged(progress: CGFloat)
}

class VideoCache {
    
    var asset: AVAsset!
    let tempFilePath: URL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("k.mov")
    var progressTimer: Timer?
    weak var delegate: VideoCacheDelegate?

    init(asset: AVAsset) {
        self.asset = asset
    }
    
    typealias ParseHandler = (_ video: URL) -> Void

    var allRangeTrimPosition: VideoTrimPosition {
        return VideoTrimPosition(leftTrim: CMTime.zero, rightTrim: self.asset.duration)
    }
    
    func parse(trimPosition: VideoTrimPosition! = nil, completion: @escaping ParseHandler) {
        let trimPosition = trimPosition == nil ? allRangeTrimPosition : trimPosition
        
        DispatchQueue.global().async {
            let session = AVAssetExportSession(asset: self.asset, presetName: AVAssetExportPresetMediumQuality)!
            session.timeRange = trimPosition!.timeRange
            try? FileManager.default.removeItem(at: self.tempFilePath)
            
            DispatchQueue.main.async {
                self.progressTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(0.1), repeats: true, block: { (timer) in
                    let progress = CGFloat(session.progress)
                    self.delegate?.onParsingProgressChanged(progress: progress)
                    if progress == 1.0 {
                        self.progressTimer?.invalidate()
                    }
                })
            }

            self.progressTimer?.invalidate()
            session.outputURL = self.tempFilePath
            session.outputFileType = AVFileType.mov
            session.exportAsynchronously {
                DispatchQueue.main.async {
                    completion(session.outputURL!)
                    self.progressTimer?.invalidate()
                }
            }
        }
    }
}
