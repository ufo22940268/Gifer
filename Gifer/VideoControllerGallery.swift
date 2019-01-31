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

let videoControllerGalleryImageCountPerGroup = 12
let videoControllerGalleryVideoLengthPerGroup = 8

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
            topAnchor.constraint(equalTo: superview!.topAnchor),
            bottomAnchor.constraint(equalTo: superview!.bottomAnchor),
            heightAnchor.constraint(equalTo: superview!.heightAnchor),
            superview!.trailingAnchor.constraint(equalTo: trailingAnchor)
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
        return (UIScreen.main.bounds.width - 16*2)/CGFloat(videoControllerGalleryImageCountPerGroup)
    }
    
    fileprivate func addImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        addArrangedSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalTo: heightAnchor),
            imageView.widthAnchor.constraint(equalToConstant: imageViewWidth)
            ])
        imageView.contentMode = .scaleAspectFill
        return imageView
    }
    
    func setImage(_ image: UIImage, on index: Int) -> Void {
        galleryImages[index].image = image
    }
}

