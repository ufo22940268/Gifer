//
//  VideoGalleryCell.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/11/24.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit

class VideoGalleryCell: UICollectionViewCell {
    
    var imageView: UIImageView!
    var durationView: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true
        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)])
        
        durationView = UILabel()
        durationView.translatesAutoresizingMaskIntoConstraints = false
        durationView.textColor = UIColor.white
        addSubview(durationView)
        NSLayoutConstraint.activate([
            durationView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            durationView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

