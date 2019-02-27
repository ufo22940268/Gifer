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

class ControlToolbarItemView: UIButton {

    var type: ToolbarItem!
    var icon: UIImageView!
    var titleView: UILabel!

    init(type: ToolbarItem, image: UIImage, title: String) {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = true
        
        setImage(image, for: .normal)
        setTitle(title, for: .normal)
        setTitleColor(UIColor(named: "mainColor"), for: .normal)
        titleLabel?.font = UIFont.systemFont(ofSize: 14)
        alignTextUnderImage()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func enable(_ enable: Bool) {

    }
}
