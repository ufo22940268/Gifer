//
//  ShareDialogController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/15.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

typealias ShareGifFileHandler = (_ file: URL) -> Void
typealias ShareDialogHandler = (_ type: ShareType) -> Void

enum ShareType {
    case wechat, photo
}

class ShareDialogController {
    
    let alertController: UIAlertController
    
    init(shareHandler: @escaping ShareDialogHandler) {
        alertController = UIAlertController(title: "分享", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "分享到微信", style: .default, handler: {action in
            shareHandler(.wechat)
        }))
        alertController.addAction(UIAlertAction(title: "保存到相册", style: .default, handler: { (action) in
            shareHandler(.photo)
        }))
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
    }
    
    func present(by controller: UIViewController) {
        controller.present(alertController, animated: true, completion: nil)
    }
}