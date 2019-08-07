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
    lazy var iconView: UIImageView = {
        let icon = UIImageView().useAutoLayout()
        icon.image = #imageLiteral(resourceName: "livephoto.png")
        icon.tintColor = .white
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 25),
            icon.heightAnchor.constraint(equalToConstant: 25)
            ])
        icon.isHidden = true
        return icon
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true
        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = false
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)])
        
        durationView = UILabel()
        durationView.isHidden = true
        durationView.translatesAutoresizingMaskIntoConstraints = false
        durationView.textColor = UIColor.white
        contentView.addSubview(durationView)
        NSLayoutConstraint.activate([
            durationView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            durationView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)])
        
        contentView.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            iconView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setVideoDuration(_ duration: String) {
        iconView.isHidden = true
        durationView.isHidden = false
        durationView.text = duration
    }
    
    func showLivePhotoIcon() {
        iconView.isHidden = false
        durationView.isHidden = true
    }
    
    func showAsPhoto() {
        iconView.isHidden = true
        durationView.isHidden = true
    }
}

