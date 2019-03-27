//
//  Debug.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/12/20.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

extension UIDevice {
    static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
}
