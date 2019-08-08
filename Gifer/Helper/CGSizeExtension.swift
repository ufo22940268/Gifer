//
//  CGSizeExtension.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/8/8.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

extension CGRect {
    static var identify: CGRect {
        return CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
    }
}
