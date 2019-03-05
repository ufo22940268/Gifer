//
//  ControlToolbarItem.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/25.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

public extension UIButton {
    
    func alignTextUnderImage(spacing: CGFloat = 6.0) {
        if let image = self.imageView?.image
        {
            let imageSize: CGSize = image.size
            self.titleEdgeInsets = UIEdgeInsets(top: spacing, left: -imageSize.width, bottom: -(imageSize.height), right: 0.0)
            let labelString = NSString(string: self.titleLabel!.text!)
            let titleSize = labelString.size(withAttributes: [NSAttributedString.Key.font: self.titleLabel!.font])
            self.imageEdgeInsets = UIEdgeInsets(top: -(titleSize.height + spacing), left: 0.0, bottom: 0.0, right: -titleSize.width)
        }
    }
}

class ControlToolbarItemView: UICollectionViewCell {

    var type: ToolbarItem!
    var icon: UIImageView!
    var titleView: UILabel!
    
    let button: UIButton!

    override init(frame: CGRect) {
        button = UIButton()
        super.init(frame: CGRect.zero)
        contentView.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)])
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor(named: "mainColor"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    }
    
    func setup(type: ToolbarItem, image: UIImage, title: String) {
        button.setImage(image, for: .normal)
        button.setTitle(title, for: .normal)
        button.alignTextUnderImage()
        button.sizeToFit()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func enable(_ enable: Bool) {

    }
}
