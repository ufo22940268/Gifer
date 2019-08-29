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
    var galleryDuration: CMTime!
    
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
            ])
        layer.cornerRadius = 4
        clipsToBounds = true
    }
    
    var itemSize: CGSize {
        return bounds.size
    }
    
    func prepareImageViews(_ count: Int) {
        for index in 0..<count {
            let imageView: UIImageView = addImageView(totalImageCount: count)
            galleryImages.append(imageView)
            if index == 0 {
                imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                imageView.layer.cornerRadius = 4
            } else if index == count - 1 {
                imageView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
                imageView.layer.cornerRadius = 4
            }
        }
    }
    
    var imageViewCount: Int {
        return galleryImages.count
    }
    
    func getImageViewWidth(totalImageCount: Int) -> CGFloat {
        let superviewWidth = self.superview!.bounds.width
        let contentWidth = superviewWidth*CGFloat(duration.seconds)/CGFloat(galleryDuration.seconds)
        
        return contentWidth/CGFloat(totalImageCount)
    }
    
    fileprivate func addImageView(totalImageCount: Int) -> UIImageView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        addArrangedSubview(imageView)
        let widthAnchor = imageView.widthAnchor.constraint(equalToConstant: getImageViewWidth(totalImageCount: totalImageCount))
        widthAnchor.identifier = "width"
        widthAnchor.isActive = true
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalTo: heightAnchor)
            ])
        imageView.contentMode = .scaleAspectFill

        return imageView
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        arrangedSubviews.forEach { (view) in
            view.constraints.findById(id: "width").constant = getImageViewWidth(totalImageCount: arrangedSubviews.count)
        }
    }
    
    func setImage(_ image: UIImage, on index: Int) -> Void {
        galleryImages[index].image = image
    }
}

