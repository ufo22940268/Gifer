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
    var filter: YPFilter?
    var stickers: [Sticker]
    
    init(asset: AVAsset, options: GifGenerator.Options) {
        self.asset = asset
        self.startProgress = options.start
        self.endProgress = options.end
        self.speed = options.speed
        self.cropArea = options.cropArea
        self.filter = options.filter
        self.stickers = options.stickers
    }
    
    public typealias ExportHandler = (_ path: URL) -> Void
    public typealias ShareHandler = (_ success: Bool) -> Void
    
    func share(complete: @escaping ExportHandler) {
        DispatchQueue.global().async {
            let options = GifGenerator.Options(start: self.startProgress, end: self.endProgress,
                                               speed: self.speed, cropArea: self.cropArea, filter: self.filter,
                                               stickers: self.stickers)
            GifGenerator(video: self.asset, options: options).run() { path in
                DispatchQueue.main.async {                    
                    complete(path)
                }
            }
        }
    }
    
    func shareToWechat(video: URL, complete: @escaping ShareHandler) {
        guard !UIDevice.isSimulator else {
            return
        }
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
                switch result {
                case .success(_):
                    complete(true)
                case .failure(_):
                    complete(false)
                }
            }
            
        }
    }
    
    func saveToPhoto(gif: URL, complete: @escaping ShareHandler) {
        let gifData = try! Data(contentsOf: gif)
        PHPhotoLibrary.shared().performChanges({
            PHAssetCreationRequest.forAsset().addResource(with: .photo, data: gifData, options: nil)
            complete(true)
        })
    }
}
