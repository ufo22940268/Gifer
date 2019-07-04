//
//  GallerySwitcher.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/4.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

enum GalleryCategory: CaseIterable {
    case video
    case livePhoto
    
    var title: String {
        switch self {
        case .video:
            return "视频"
        case .livePhoto:
            return "实况照片"
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
        }
    }
    
    weak var delegate: GallerySwitcherDelegate?
    
    override var isSelected: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                if self.isSelected {
                    self.imageView?.transform = .identity
                } else {
                    self.imageView?.transform = CGAffineTransform(rotationAngle: .pi)
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        tintColor = .yellowActiveColor
        setTitleColor(.yellowActiveColor, for: .normal)
        setImage(#imageLiteral(resourceName: "chevron-square-up.png"), for: .normal)
        imageView?.contentMode = .center
        semanticContentAttribute = .forceRightToLeft
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        imageView?.transform = CGAffineTransform(rotationAngle: .pi)

        addTarget(self, action: #selector(onClick), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func onClick() {
        isSelected = !isSelected
        delegate?.onToggleGalleryPanel(slideDown: isSelected)
    }
}
