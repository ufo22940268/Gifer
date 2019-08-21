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
import MessageUI
import Social
//import TwitterKit
//import TwitterCore

typealias ShareEmailSourceViewController = UIViewController & MFMailComposeViewControllerDelegate

class ShareManager: NSObject {
    var options: GifGenerator.Options!
    var playerItem: ImagePlayerItem!
    
    init(playerItem: ImagePlayerItem, options: GifGenerator.Options) {
        self.playerItem = playerItem
        self.options = options
    }
    
    public typealias ExportHandler = (_ path: URL) -> Void
    public typealias ShareHandler = (_ success: Bool) -> Void
    
    func share(type: ShareType, complete: @escaping ExportHandler) {
        DispatchQueue.global().async {
            GifGenerator(playerItem: self.playerItem, options: self.options).run() { path in
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
    
//    func shareToTwitter(video: URL, from host: UIViewController, complete: @escaping ShareHandler) {
//        // Swift
//        let composer = TWTRComposer()
//
//        composer.setText("just setting up my Twitter Kit")
//
//        // Called from a UIViewController
////        composer.show(from: host.navigationController!) { (_) in
////            print("finished")
////            complete(true)
////        }
//    }
    
    func shareBySystem(gif: URL, host: UIViewController, complete: @escaping ShareHandler) {
        if let gifData = try? Data(contentsOf: gif) {
            let vc = UIActivityViewController(activityItems: [gifData], applicationActivities: nil)
            host.present(vc, animated: true, completion: nil)
        } else {
            complete(false)
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
                case let .failure(error):
                    print("error: \(error)")
                    complete(false)
                }
            }
        }
    }
    
    func saveToPhoto(gif: URL, complete: @escaping ShareHandler) {
        if UIDevice.isDebug && UIDevice.isSimulator {
            complete(true)
        } else {
            let gifData = try! Data(contentsOf: gif)
            PHPhotoLibrary.shared().performChanges({
                PHAssetCreationRequest.forAsset().addResource(with: .photo, data: gifData, options: nil)
                complete(true)
            })
        }
    }
    
    func shareToEmail(gif: URL, from hostVC: ShareEmailSourceViewController) {
        let vc = MFMailComposeViewController()
        let gifData = try! Data(contentsOf: gif)
        vc.addAttachmentData(gifData, mimeType: "image/gif", fileName: "one.gif")
        vc.mailComposeDelegate = hostVC
        hostVC.present(vc, animated: true, completion: nil)
    }
}

