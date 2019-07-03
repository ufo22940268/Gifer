//
//  Config.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/2.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

struct Config {
    #if DEBUG
    static let defaultRate: Float = UIDevice.isSimulator ? 0.3 : 1
    #else
    static let defaultRate: Float = 1
    #endif
}
