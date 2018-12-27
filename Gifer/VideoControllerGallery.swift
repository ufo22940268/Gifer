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

let videoControllerGalleryImageCountPerGroup = 8

class VideoControllerGallery: UIStackView {

    var galleryImages = [UIImageView]()
    var duration: CMTime!
    
    init() {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        axis = .horizontal
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setup() {
        alignment = .center
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview!.leadingAnchor),
            topAnchor.constraint(equalTo: superview!.layoutMarginsGuide.topAnchor),
            bottomAnchor.constraint(equalTo: superview!.layoutMarginsGuide.bottomAnchor),
            trailingAnchor.constraint(equalTo: superview!.trailingAnchor)
            ])
        
    }
    
    func prepareImageViews(_ count: Int) {
        for _ in 0..<count {
            galleryImages.append(addImageView())
        }
    }
    
    var imageViewCount: Int {
        return galleryImages.count
    }
    
    var imageViewWidth: CGFloat {
        return superview!.bounds.width/CGFloat(videoControllerGalleryImageCountPerGroup)
    }
        
    fileprivate func addImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        addArrangedSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalTo: heightAnchor, constant: -VideoControllerConstants.topAndBottomInset*2),
            imageView.widthAnchor.constraint(equalToConstant: imageViewWidth)
            ])
        imageView.contentMode = .scaleAspectFill
        return imageView
    }
    
    func setImage(_ image: UIImage, on index: Int) -> Void {
        galleryImages[index].image = image
    }
}

