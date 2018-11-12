//
//  VideoController.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/11/12.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class VideoGallery: UIStackView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        axis = .horizontal
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func addImage(_ image: UIImage) -> Void {
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalTo: heightAnchor),
            imageView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width/10)
            ])
        imageView.contentMode = .scaleAspectFill
    }
}


class VideoController: UIView {
    
    var galleryView: VideoGallery!
    
    override func awakeFromNib() {
        galleryView = VideoGallery(frame: CGRect.zero)
        addSubview(galleryView)
        NSLayoutConstraint.activate([
            galleryView.leadingAnchor.constraint(equalTo: leadingAnchor),
            galleryView.trailingAnchor.constraint(equalTo: trailingAnchor),
            galleryView.topAnchor.constraint(equalTo: topAnchor),
            galleryView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
    }
    
    
    fileprivate func loadGallery(withImages images: [UIImage]) -> Void {
        for image in images {
            galleryView.addImage(image)
        }
    }
    
    func load(playerItem: AVPlayerItem) -> Void {
        let thumbernails = playerItem.asset.extractThumbernails()
        loadGallery(withImages: thumbernails)
    }
}
