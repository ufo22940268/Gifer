//
//  ShareDialogController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/15.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AVKit

typealias ShareGifFileHandler = (_ file: URL) -> Void
typealias ShareDialogHandler = (_ type: ShareType) -> Void

enum ShareType {
    case wechat, photo, wechatSticker
    
    var initialGifSize: CGSize {
        switch self {
        case .wechatSticker:
            return CGSize(width: 150, height: 150)
        default:
            return CGSize(width: 500, height: 500)
        }
    }
    
    var sizeLimitation: Double {
        switch self {
        case .wechat:
            return 5
        case .photo:
            return 40
        case .wechatSticker:
            return 0.5
        }
    }

    var lowestSize: CGSize {
        switch self {
        case .wechatSticker:
            return CGSize(width: 100, height: 100)
        default:
            return CGSize(width: 200, height: 200)
        }
    }
    
    func isEnabled(duration: CMTime) -> Bool {
        switch self {
        case .wechatSticker:
            return duration.seconds <= 5
        default:
            return true
        }
    }
}

class ShareDialogController {
    
    let alertController: UIAlertController
    
    init(duration: CMTime, shareHandler: @escaping ShareDialogHandler, cancelHandler: @escaping () -> Void) {
        alertController = UIAlertController(title: "分享", message: nil, preferredStyle: .actionSheet)
        
        if ShareType.wechatSticker.isEnabled(duration: duration) {
            alertController.addAction(UIAlertAction(title: "添加到微信表情", style: .default, handler: {action in
                shareHandler(.wechatSticker)
            }))
        }
        
        if ShareType.wechat.isEnabled(duration: duration) {
            alertController.addAction(UIAlertAction(title: "分享到微信", style: .default, handler: {action in
                shareHandler(.wechat)
            }))
        }
        
        alertController.addAction(UIAlertAction(title: "保存到相册", style: .default, handler: { (action) in
            shareHandler(.photo)
        }))
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { _ in cancelHandler() }))
    }
    
    func present(by controller: UIViewController) {
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = controller.view
        }
        controller.present(alertController, animated: true, completion: nil)
    }
}
