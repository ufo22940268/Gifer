//
//  UIViewControllerExtensions.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/18.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func makeToast(message: String, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {_ in completion?()}))
        present(alertController, animated: true, completion: nil)
    }
}
