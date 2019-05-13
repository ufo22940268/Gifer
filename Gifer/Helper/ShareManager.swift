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
    var options: GifGenerator.Options!
    var asset: AVAsset!
    
    init(asset: AVAsset, options: GifGenerator.Options) {
        self.asset = asset
        self.options = options
    }
    
    public typealias ExportHandler = (_ path: URL) -> Void
    public typealias ShareHandler = (_ success: Bool) -> Void
    
    func share(type: ShareType, complete: @escaping ExportHandler) {
        DispatchQueue.global().async {
            GifGenerator(video: self.asset, options: self.options).run() { path in
                DispatchQueue.main.async {                    
                    complete(path)
                }
            }
        }
    }
    
//    func shareToWeibo(video: URL, complete: @escaping ShareHandler) {
//        guard !UIDevice.isSimulator else {
//            return
//        }
//        let gifData = try! Data(contentsOf: video)
//        DispatchQueue.main.async {
//            let monkeyMessage = MonkeyKing.Message.weibo(.default(info: (
//                title: nil,
//                description: nil,
//                thumbnail: UIImage(data: gifData),
//                media: .gif(gifData)
//                ), accessToken: <#T##String?#>))
//
//            MonkeyKing.deliver(monkeyMessage) { (result) in
//                print("result: \(result)")
//                switch result {
//                case .success(_):
//                    complete(true)
//                case .failure(_):
//                    complete(false)
//                }
//            }
//
//        }
//    }

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
