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
    var duration: CMTime!
    
    init(totalImageCount: Int) {
        super.init(frame: CGRect.zero)
        self.totalImageCount = totalImageCount
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
            imageView.widthAnchor.constraint(equalToConstant: 40)
            ])
        imageView.contentMode = .scaleAspectFill
        return imageView
    }

    
    func setImage(_ image: UIImage, on index: Int) -> Void {
        galleryImages[index].image = image
    }
}

