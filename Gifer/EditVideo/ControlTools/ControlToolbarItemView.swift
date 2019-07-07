//
//  ControlToolbarItem.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/25.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit


class ControlToolbarItemView: UICollectionViewCell {

    var type: ToolbarItem!
    var icon: UIImageView!
    var titleView: UILabel!
    
    let button: UIButton!
    
    override var isHighlighted: Bool {
        didSet {
            button.isHighlighted = isHighlighted
            button.titleLabel?.isHighlighted = isHighlighted
        }
    }

    override init(frame: CGRect) {
        button = UIButton()
        super.init(frame: CGRect.zero)
        contentView.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)])
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = false
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    }
    
    func setup(type: ToolbarItem, image: UIImage, title: String) {
        button.setImage(image, for: .normal)
        button.setTitle(title, for: .normal)        
        button.alignTextUnderImage()
        button.sizeToFit()
    }
    
    override func tintColorDidChange() {        
        button.setTitleColor(tintColor, for: .normal)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func enable(_ enable: Bool) {

    }
}
