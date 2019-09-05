//
//  ShotPhotoCountView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/9/5.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class ShotPhotoCountView: UIView {
    
    lazy var countView: UILabel = {
        let view = UILabel().useAutoLayout()
        view.adjustsFontSizeToFitWidth = true
        view.font = UIFont.preferredFont(forTextStyle: .footnote)
        view.textColor = .lightGray
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.6)
        layer.cornerRadius = intrinsicContentSize.height/2
        addSubview(countView)
        NSLayoutConstraint.activate([
            countView.centerXAnchor.constraint(equalTo: centerXAnchor),
            countView.centerYAnchor.constraint(equalTo: centerYAnchor),
            countView.widthAnchor.constraint(equalTo: layoutMarginsGuide.widthAnchor),
            countView.heightAnchor.constraint(equalTo: layoutMarginsGuide.heightAnchor),
            ])
        countView.text = "10"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 30, height: 30)
    }
}
