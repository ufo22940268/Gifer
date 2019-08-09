//
//  GallerySwitcher.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/4.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import Photos

enum GalleryCategory: CaseIterable {
    case video
    case livePhoto
    case photo
    
    var title: String {
        switch self {
        case .video:
            return NSLocalizedString("Video", comment: "Video item in category selector")
        case .livePhoto:
            return NSLocalizedString("Live Photo", comment: "Live Photo item in category selector")
        case .photo:
            return NSLocalizedString("Photo", comment: "Photo item in category selector")
        }
    }
    
    var icon: UIImage {
        switch self {
        case .video:
            return #imageLiteral(resourceName: "video.png")
        case .livePhoto:
            return #imageLiteral(resourceName: "livephoto.png")
        case .photo:
            return #imageLiteral(resourceName: "Image Category.png")
        }
    }
    
    var mediaSubtype: PHAssetMediaSubtype? {
        switch self {
        case .livePhoto:
            return .photoLive
        default:
            return nil
        }
    }
    
    var mediaType: PHAssetMediaType? {
        switch self {
        case .livePhoto:
            return nil
        case .video:
            return .video
        case .photo:
            return .image
        }
    }
}

protocol GallerySwitcherDelegate: class {
    func onToggleGalleryPanel(slideDown: Bool)
}

class GallerySwitcher: UIButton {

    var category: GalleryCategory! {
        didSet {
            setTitle(category.title, for: .normal)
            sizeToFit()
        }
    }
    
    weak var delegate: GallerySwitcherDelegate?
    
    override var isSelected: Bool {
        didSet {
            if self.isSelected {
                self.imageView?.transform = .identity
            } else {
                self.imageView?.transform = CGAffineTransform(rotationAngle: .pi)
            }
        }
    }
    
    func setSelected(_ selected: Bool, anim: Bool) {
        if anim {
            UIView.animate(withDuration: 0.15) {
                self.isSelected = selected
            }
        } else {
            isSelected = selected
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel?.textAlignment = .center
        tintColor = .yellowActiveColor
        setTitleColor(.yellowActiveColor, for: .normal)
        setImage(#imageLiteral(resourceName: "chevron-square-up.png"), for: .normal)
        imageView?.contentMode = .center
        semanticContentAttribute = .forceRightToLeft
        titleEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -4)
        imageEdgeInsets = UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 0)
        imageView?.transform = CGAffineTransform(rotationAngle: .pi)

        addTarget(self, action: #selector(onClick), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func onClick() {
        setSelected(!isSelected, anim: true)
        delegate?.onToggleGalleryPanel(slideDown: isSelected)
    }
}
