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
//        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = image
        addSubview(imageView)
        
//        NSLayoutConstraint.activate([
//            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            imageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0),
//            imageView.widthAnchor.constraint(equalTo: heightAnchor, multiplier: image.size.width/image.size.height),
//            imageView.centerYAnchor.constraint(equalTo: centerYAnchor)])
                
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
