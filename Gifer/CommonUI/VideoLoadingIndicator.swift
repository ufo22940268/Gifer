//
//  VideoLoadingIndicator.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/20.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class VideoLoadingIndicator: UIView {
    
    var indicator: UIActivityIndicatorView!

    init() {
        super.init(frame: CGRect.zero)
        indicator = UIActivityIndicatorView(style: .whiteLarge)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        indicator.startAnimating()
        indicator.isHidden = true
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func show() {
        indicator.isHidden = false
    }
    

    func dismiss() {
        indicator.isHidden = true
    }
}
