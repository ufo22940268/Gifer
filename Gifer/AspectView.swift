//
//  AspectView.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/12/6.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class AspectView: UIView {
    
    var imageView: UIImageView!
    
    init(frame: CGRect, image: UIImage) {
        super.init(frame: frame)
        clipsToBounds = true
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = image
        addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
