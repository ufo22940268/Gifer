//
//  CommonConstraints.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/18.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

struct CommonConstraints {
    var centerX: NSLayoutConstraint
    var centerY: NSLayoutConstraint
    var width: NSLayoutConstraint
    var height: NSLayoutConstraint
    
    var centerXSnapshot: CGFloat = 0
    var centerYSnapshot: CGFloat = 0
    var widthSnapshot: CGFloat = 0
    var heightSnapshot: CGFloat = 0
    
    init(child: UIView, parent: UIView) {
        self.centerX = child.centerXAnchor.constraint(equalTo: parent.centerXAnchor)
        self.centerY = child.centerYAnchor.constraint(equalTo: parent.centerYAnchor)
        self.width = child.widthAnchor.constraint(equalTo: parent.widthAnchor)
        self.height = child.heightAnchor.constraint(equalTo: parent.heightAnchor)
    }
    
    init(centerX: NSLayoutConstraint, centerY: NSLayoutConstraint, width: NSLayoutConstraint, height: NSLayoutConstraint) {
        self.centerX = centerX
        self.centerY = centerY
        self.width = width
        self.height = height
    }
    
    mutating func snapshot() {
        centerXSnapshot = centerX.constant
        centerYSnapshot = centerY.constant
        widthSnapshot = width.constant
        heightSnapshot = height.constant
    }
    
    mutating func rollback() {
        centerX.constant = centerXSnapshot
        centerY.constant = centerYSnapshot
        width.constant = widthSnapshot
        height.constant = heightSnapshot
    }
    
    mutating func copy(from constraints: CommonConstraints) {
        centerX.constant = constraints.centerX.constant
        centerY.constant = constraints.centerY.constant
        width.constant = constraints.width.constant
        height.constant = constraints.height.constant
    }
    
    func activeAll() {
        NSLayoutConstraint.activate([centerX, centerY, width, height])
    }
}

