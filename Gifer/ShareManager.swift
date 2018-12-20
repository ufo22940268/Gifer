//
//  ShareManager.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/12/13.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import ImageIO
import MobileCoreServices
import Photos
import MonkeyKing

class ShareManager {
    
    var asset: AVAsset!
    var startProgress: CGFloat!
    var endProgress: CGFloat!
    
    init(asset: AVAsset, startProgress: CGFloat, endProgress: CGFloat) {
        self.asset = asset
        self.startProgress = startProgress
        self.endProgress = endProgress
    }
    
    func share() {
        GifGenerator(video: asset).run(start: self.startProgress, end: self.endProgress) { path in
            print("path: \(path)")
            if !UIDevice.isSimulator {
                self.shareToWechat(video: path)
            }
        }
    }
    
    func shareToWechat(video: URL) {
        let gifData = try! Data(contentsOf: video)
        DispatchQueue.main.async {
            let monkeyMessage = MonkeyKing.Message.weChat(.session(info: (
                title: nil,
                description: nil,
                thumbnail: UIImage(data: gifData),
                media: .gif(gifData)
            )))

            MonkeyKing.deliver(monkeyMessage) { (result) in
                print("result: \(result)")
            }
            
        }
    }
}
