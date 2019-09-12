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
        label.backgroundColor = .clear
        return label
    }()
    
    lazy var circleView: VideoProgressCircle = {
        let view = VideoProgressCircle()
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 32),
            view.heightAnchor.constraint(equalToConstant: 32)])
        view.customDelegate = self
        return view
    }()
    
    var progress: CGFloat = 0 {
        didSet {
            self.circleView.progress = self.progress
        }
    }
    
    var hideWhenCompleted = false {
        didSet {
            if progress != 1 {
                progress = 1
            }
        }
    }

    override func awakeFromNib() {
        setup()
    }
    
    private func setup() {
        isLayoutMarginsRelativeArrangement = true
        layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        translatesAutoresizingMaskIntoConstraints = false
        axis = .horizontal
        spacing = 8
        tintColor = .lightText
        
        tintAdjustmentMode = .normal
        
        addArrangedSubview(circleView)
        addArrangedSubview(messageView)
        messageView.text = "正在下载视频"
        messageView.sizeToFit()
    }
}

extension VideoProgressLoadingIndicator: VideoProgressCircleDelegate {
    func onStopped(_ circleView: VideoProgressCircle) {
        self.isHidden = true
    }
}
