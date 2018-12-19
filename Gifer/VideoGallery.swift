//
//  VideoGallery.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/11/24.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class VideoControllerGallery: UIStackView {

    var totalImageCount: Int!
    var galleryImages = [UIImageView]()
    
    init(totalImageCount: Int) {
        super.init(frame: CGRect.zero)
        self.totalImageCount = totalImageCount
        translatesAutoresizingMaskIntoConstraints = false
        axis = .horizontal
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    let faderBackgroundColor = UIColor(white: 0.7, alpha: 0.4)
    
    lazy var leftFader: UIView = {
        let left = UIView()
        left.translatesAutoresizingMaskIntoConstraints = false
        left.backgroundColor = faderBackgroundColor
        return left
    }()
    
    lazy var rightFader: UIView = {
        let right = UIView()
        right.translatesAutoresizingMaskIntoConstraints = false
        right.backgroundColor = faderBackgroundColor
        return right
    }()
    var leftFaderWidthConstraint: NSLayoutConstraint!
    var rightFaderWidthConstraint: NSLayoutConstraint!
    
    func setup() {
        alignment = .center
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview!.layoutMarginsGuide.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview!.layoutMarginsGuide.trailingAnchor),
            topAnchor.constraint(equalTo: superview!.layoutMarginsGuide.topAnchor),
            bottomAnchor.constraint(equalTo: superview!.layoutMarginsGuide.bottomAnchor)
            ])
        
        addSubview(leftFader)
        leftFaderWidthConstraint = leftFader.widthAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            leftFaderWidthConstraint,
            leftFader.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftFader.topAnchor.constraint(equalTo: topAnchor),
            leftFader.heightAnchor.constraint(equalTo: heightAnchor)])
        
        addSubview(rightFader)
        rightFaderWidthConstraint = rightFader.widthAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            rightFaderWidthConstraint,
            rightFader.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightFader.topAnchor.constraint(equalTo: topAnchor),
            rightFader.heightAnchor.constraint(equalTo: heightAnchor)])
        
        distribution = .fillEqually
        for _ in 0..<totalImageCount {
            galleryImages.append(addImageView())
        }
    }
    
    fileprivate func addImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        addArrangedSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalTo: heightAnchor, constant: -VideoControllerConstants.topAndBottomInset*2),
            ])
        imageView.contentMode = .scaleAspectFill
        return imageView
    }

    
    func setImage(_ image: UIImage, on index: Int) -> Void {
        galleryImages[index].image = image
    }
    
    func updateByTrim(trimPosition position: VideoTrimPosition) {
        leftFaderWidthConstraint.constant = position.leftTrim*bounds.width
        rightFaderWidthConstraint.constant = bounds.width - position.rightTrim*bounds.width
    }
}

