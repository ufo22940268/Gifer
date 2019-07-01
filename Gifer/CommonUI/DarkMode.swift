//
//  DarkMode.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/11.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

struct DarkMode {
    
    static func enable(in viewController: UIViewController) {
        guard let navigationController = viewController.navigationController else { return }
        navigationController.navigationBar.barStyle = .black
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.barTintColor = UIColor(named: "darkBackgroundColor")
        navigationController.navigationBar.shadowImage = UIImage()
        
        navigationController.navigationBar.tintColor = .white
    }
}
