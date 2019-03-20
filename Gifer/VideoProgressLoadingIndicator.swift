//
//  VideoProgressLoadingIndicator.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/20.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class VideoProgressLoadingIndicator: UIStackView {

    lazy var messageView: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = tintColor
        return label
    }()
    
    override func awakeFromNib() {
        setup()
    }
    
    private func setup() {
        axis = .horizontal
        tintColor = UIColor.darkGray

        addArrangedSubview(messageView)
        messageView.text = "正在下载视频"
        messageView.sizeToFit()
    }
}
