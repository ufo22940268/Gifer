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


class ShareDialogController {
    
    let alertController: UIAlertController
    
    init(duration: CMTime, shareHandler: @escaping ShareHandler, cancelHandler: @escaping () -> Void) {
        alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
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
    
    func present(by controller: UINavigationController) {
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = controller.view
        }
        controller.present(alertController, animated: true, completion: nil)
    }
    
    func present(by controller: UIViewController) {
        
    }
}
