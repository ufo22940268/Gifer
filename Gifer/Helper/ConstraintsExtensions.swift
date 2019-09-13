//
//  Constraints.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/30.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

extension NSLayoutConstraint {
    func activeAndReturn() -> NSLayoutConstraint {
        isActive = true
        return self
    }
    
    func with(priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}
