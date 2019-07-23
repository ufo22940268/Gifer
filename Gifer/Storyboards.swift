//
//  Storyboards.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/29.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

enum AppStoryboard: String {
    case Frame
    case Main
    case Edit
    case Sticker

    var instance: UIStoryboard {
        return UIStoryboard(name: self.rawValue, bundle: nil)
    }
}
