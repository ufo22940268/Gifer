//
//  VideoController.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/11/12.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class VideoGallery: UIStackView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
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
    
    func loadGallery(withImages images: [UIImage]) -> Void {
        
    }
}
