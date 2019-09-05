//
//  ShotPhotoCountView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/9/5.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class ShotPhotoCountView: UIView {
    
    override func awakeFromNib() {
        backgroundColor = .yellow
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 50, height: 50)
    }
}
