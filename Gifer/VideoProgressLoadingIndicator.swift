//
//  VideoProgressLoadingIndicator.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/20.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class VideoProgressLoadingIndicator: UIVisualEffectView {

    lazy var messageView: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = tintColor
        label.backgroundColor = .clear
        return label
    }()
    
    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        return view
    }()
    
    override func awakeFromNib() {
        setup()
    }
    
    private func setup() {
        layer.cornerRadius = 8
        clipsToBounds = true
        effect = UIBlurEffect(style: .extraLight)
        tintColor = UIColor.darkGray
        
        contentView.addSubview(stackView)

        stackView.addArrangedSubview(messageView)
        messageView.text = "正在下载视频"
        messageView.sizeToFit()
        
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalTo: stackView.widthAnchor),
            heightAnchor.constraint(equalTo: stackView.heightAnchor)
            ])
    }
}
