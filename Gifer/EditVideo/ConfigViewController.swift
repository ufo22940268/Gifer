//
//  ConfigViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/5/14.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class ConfigViewController: UIViewController {
    
    var contentView: UIView
    var centerX: NSLayoutConstraint!

    init(contentView: UIView) {
        self.contentView = contentView
        super.init(nibName: nil, bundle: nil)
        
        view.clipsToBounds = true
        view.backgroundColor = .clear
        
        view.addSubview(contentView)
        centerX = contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        NSLayoutConstraint.activate([
            centerX,
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentView.widthAnchor.constraint(equalTo: view.widthAnchor),
            contentView.heightAnchor.constraint(equalTo: view.heightAnchor)
            ])
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
