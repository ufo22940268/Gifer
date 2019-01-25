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

class CropMenuView: UIStackView {
    
    var delegate: CropMenuViewDelegate!

    init() {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        
        axis = .horizontal
        let restoreButton = UIButton(type: .system)
        restoreButton.setTitle("还原", for: .normal)
        restoreButton.sizeToFit()
        addArrangedSubview(restoreButton)
        sizeToFit()

        restoreButton.addTarget(delegate, action: #selector(CropMenuViewDelegate.onResetCrop), for: .touchUpInside)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
