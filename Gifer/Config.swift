//
//  Config.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/2.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation

struct Config {
    #if DEBUG
    static let defaultRate: Float = 0.3
    #else
    static let defaultRate: Float = 1
    #endif
}
