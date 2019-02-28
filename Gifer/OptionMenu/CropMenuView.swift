//
//  CropMenuView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/24.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

@objc protocol CropMenuViewDelegate: class {
    func onResetCrop()
}

class CropMenuView: UIScrollView, Transaction {
    
    var customDelegate: CropMenuViewDelegate!
    var contentView: UIStackView!

    init() {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = #colorLiteral(red: 0.0862745098, green: 0.09019607843, blue: 0.09411764706, alpha: 1)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 60)])
        
        contentView = UIStackView()
        contentView.axis = .horizontal
        contentView.spacing = 16
        contentView.isLayoutMarginsRelativeArrangement = true
        contentView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        
        
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func commitChange() {
    }
    
    func rollbackChange() {
    }
}

class CropSizeIcon: UIView {
    
    override func draw(_ rect: CGRect) {
        
    }
}
