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
    lazy var selectPhotoSequenceView: UILabel = {
        let view = UILabel().useAutoLayout()
        view.textColor = .white
        view.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        view.isHidden = true
        view.textAlignment = .center
        view.backgroundColor = .yellowActiveColor
        return view
    }()
    
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
        
        contentView.addSubview(selectPhotoSequenceView)
        NSLayoutConstraint.activate([
            selectPhotoSequenceView.widthAnchor.constraint(equalToConstant: 30),
            selectPhotoSequenceView.heightAnchor.constraint(equalTo: selectPhotoSequenceView.widthAnchor),
            selectPhotoSequenceView.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectPhotoSequenceView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setVideoDuration(_ duration: String) {
        iconView.isHidden = true
        durationView.isHidden = false
        durationView.text = duration
        selectPhotoSequenceView.isHidden = true
    }
    
    func showLivePhotoIcon() {
        iconView.isHidden = false
        durationView.isHidden = true
        selectPhotoSequenceView.isHidden = true
    }
    
    func showAsPhoto(sequence: Int?) {
        iconView.isHidden = true
        durationView.isHidden = true
        if let sequence = sequence {
            selectPhotoSequenceView.isHidden = false
            selectPhotoSequenceView.text = String(sequence)
        } else {
            selectPhotoSequenceView.isHidden = true
        }
    }
}

