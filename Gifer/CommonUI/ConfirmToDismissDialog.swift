//
//  ConfirmToDismissDialog.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/20.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

protocol Presentable {
    func present(by: UIViewController, complete: @escaping () -> Void)
}

class ConfirmToDismissDialog: Presentable {
    
    var alertDialog: UIAlertController!
    var complete: (() -> Void)?
    
    init() {
        alertDialog = UIAlertController(title: nil, message: "确认退出将会放弃修改", preferredStyle: .alert)
        alertDialog.addAction(UIAlertAction(title: "确认", style: .default, handler: { (_) in
            self.complete?()
        }))
        alertDialog.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
    }
    
    func present(by viewController: UIViewController, complete: @escaping () -> Void) {
        self.complete = complete
        viewController.present(alertDialog, animated: true, completion: nil)
    }
}
