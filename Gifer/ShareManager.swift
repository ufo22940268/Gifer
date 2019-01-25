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
    var startProgress: CMTime!
    var endProgress: CMTime!
    var speed: Float
    var cropArea: CGRect
    
    init(asset: AVAsset, startProgress: CMTime, endProgress: CMTime, speed: Float, cropArea: CGRect) {
        self.asset = asset
        self.startProgress = startProgress
        self.endProgress = endProgress
        self.speed = speed
        self.cropArea = cropArea
    }
    
    func share(complete: @escaping () -> Void) {
        DispatchQueue.global().async {
            let options = GifGenerator.Options(start: self.startProgress, end: self.endProgress, speed: self.speed, cropArea: self.cropArea)
            GifGenerator(video: self.asset, options: options).run() { path in
                if !UIDevice.isSimulator {
                    self.shareToWechat(video: path, complete: complete)
                } else {
                    complete()
                }
            }
        }
    }
    
    func shareToWechat(video: URL, complete: @escaping () -> Void) {
        let gifData = try! Data(contentsOf: video)
        DispatchQueue.main.async {
            let monkeyMessage = MonkeyKing.Message.weChat(.session(info: (
                title: nil,
                description: nil,
                thumbnail: UIImage(data: gifData),
                media: .gif(gifData)
            )))

            complete()  
            MonkeyKing.deliver(monkeyMessage) { (result) in
                print("result: \(result)")
            }
            
        }
    }
}
