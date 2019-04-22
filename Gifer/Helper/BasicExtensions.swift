//
//  BasicExtensions.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/27.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    @discardableResult
    func useAutoLayout() -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        return self
    }
    
    @discardableResult
    func useSameSizeAsParent() -> Self {
        self.useAutoLayout()
        guard let superview = superview else { fatalError() }
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            topAnchor.constraint(equalTo: superview.topAnchor),
            widthAnchor.constraint(equalTo: superview.widthAnchor),
            heightAnchor.constraint(equalTo: superview.heightAnchor)
            ])
        return self
    }
}
