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
    
    var gifSize: CGFloat {
        switch self {
        case .wechat:
            return 400
        case .photo:
            return 600
        }
    }
}

class ShareDialogController {
    
    let alertController: UIAlertController
    
    init(shareHandler: @escaping ShareDialogHandler, cancelHandler: @escaping () -> Void) {
        alertController = UIAlertController(title: "分享", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "分享到微信", style: .default, handler: {action in
            shareHandler(.wechat)
        }))
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
