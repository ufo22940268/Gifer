//
//  ControlToolbarConfirmPrompt.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/26.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

fileprivate class ConfirmExtraButton: UIImageView {
    
    enum ButtonType {
        case ok, cancel
    }
    
    init(type: ButtonType) {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
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

class ControlToolbarConfirmPrompt: UIStackView {
    
    private var okButton: ConfirmExtraButton!
    private var cancelButton: ConfirmExtraButton!

    init(contentView: UIView) {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        addArrangedSubview(contentView)
        
        let extraView = UIStackView()
        addArrangedSubview(extraView)
        extraView.translatesAutoresizingMaskIntoConstraints = false
        extraView.axis = .horizontal
        extraView.distribution = .fillEqually
        extraView.isLayoutMarginsRelativeArrangement = true
        
        okButton = ConfirmExtraButton(type: .ok)
        cancelButton = ConfirmExtraButton(type: .cancel)
        extraView.addArrangedSubview(cancelButton)
        extraView.addArrangedSubview(okButton)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
