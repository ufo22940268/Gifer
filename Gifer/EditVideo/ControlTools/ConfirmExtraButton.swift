//
//  ConfirmExtraButton.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/26.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class ConfirmExtraButton: UIButton {
    
    enum ActionType {
        case ok, cancel
    }
    
    init(type: ActionType) {
        super.init(frame: CGRect.zero)
        tintColor = .white
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = true
        var image: UIImage
        switch type {
        case .ok:
            image = #imageLiteral(resourceName: "checkmark-outline.png")
        case .cancel:
            image = #imageLiteral(resourceName: "close-outline.png")
        }
        setImage(image, for: .normal)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44)])
        if type == .cancel {
            tintAdjustmentMode = .dimmed
        }
        contentMode = .center
        backgroundColor = UIColor(named: "darkBackgroundColor")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

