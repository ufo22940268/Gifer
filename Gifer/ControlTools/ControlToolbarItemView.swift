//
//  ControlToolbarItem.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/25.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
class ControlToolbarItemView: UIStackView {
    
    var type: ToolbarItem!
    var icon: UIImageView!
    var titleView: UILabel!

    init(type: ToolbarItem, image: UIImage, title: String) {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = true
        self.type = type
        
        axis = .vertical
        spacing = 8
        alignment = .center
        
        icon = UIImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(icon)
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 32),
            icon.heightAnchor.constraint(equalToConstant: 32),
            ])
        icon.clipsToBounds = true
        icon.image = image
        icon.contentMode = .scaleAspectFit
        
        titleView = UILabel()
        titleView.translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(titleView)
        titleView.text = title
        titleView.textColor = UIColor(named: "mainColor")
        titleView.font = UIFont.systemFont(ofSize: 14)
        titleView.sizeToFit()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func enable(_ enable: Bool) {
        
    }
}

extension ControlToolbarItemView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        tintAdjustmentMode = .dimmed
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        tintAdjustmentMode = .normal
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        tintAdjustmentMode = .normal
    }
    
    override func tintColorDidChange() {
        titleView.textColor = tintColor
    }
}
