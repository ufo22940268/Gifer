//
//  OverlayComponentRender.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/4/1.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

protocol OverlayComponentRenderable {
    func copy() -> OverlayComponentRender
}

typealias OverlayComponentRender = UIView & OverlayComponentRenderable
