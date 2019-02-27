//
//  ConfirmExtraButton.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/26.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class ConfirmExtraButton: UIImageView {
    
    enum ButtonType {
        case ok, cancel
    }
    
    init(type: ButtonType) {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = true
        switch type {
        case .ok:
            image = #imageLiteral(resourceName: "checkmark-outline.png")
        case .cancel:
            image = #imageLiteral(resourceName: "close-outline.png")
        }
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44)])
        tintColor = UIColor(named: "mainColor")
        contentMode = .center
        backgroundColor = #colorLiteral(red: 0.0862745098, green: 0.09019607843, blue: 0.09411764706, alpha: 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

