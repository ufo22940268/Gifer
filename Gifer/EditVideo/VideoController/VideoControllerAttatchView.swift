//
//  VideoControllerAttatchTrim.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/4/23.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class VideoControllerAttatchTrim: ControllerTrim {

    override var changeBackgroundWhenNeeded: Bool {
        return false
    }
    
    override var faderBackgroundColor: UIColor {
        return UIColor(named: "darkBackgroundColor")!
    }
    
    func update(trimPosition: VideoTrimPosition) {
        let totalWidth = bounds.width
        if let duration = duration, totalWidth > 0 {
            let leftPercent = trimPosition.leftTrim.seconds/duration.seconds
            let rightPercent = (duration.seconds - trimPosition.rightTrim.seconds)/duration.seconds
            leftTrimLeadingConstraint.constant = totalWidth*CGFloat(leftPercent)
            rightTrimTrailingConstraint.constant = -totalWidth*CGFloat(rightPercent)
        }
    }
    
}

protocol VideoControllerAttachDelegate: class {
    func onAttachChanged(component: OverlayComponent, trimPosition: VideoTrimPosition)
}

class VideoControllerAttachView: UIView {
    
    lazy var galleryView: VideoControllerAttachGallery = {
        let view = VideoControllerAttachGallery().useAutoLayout()
        view.dataSource = self
        return view
    }()
    
    var imageSticker: UIImage?
    var textSticker: String?
    
    lazy var trimView: VideoControllerAttatchTrim = {
        let view = VideoControllerAttatchTrim().useAutoLayout()
        view.trimDelegate = self
        return view
    }()
    
    var component: OverlayComponent!
    weak var customDelegate: VideoControllerAttachDelegate?
    var duration: CMTime! {
        didSet {
            trimView.duration = duration
            trimView.galleryDuration = duration
        }
    }
    
    enum Mode {
        case image, text
    }
    
    var mode: Mode? {
        if imageSticker != nil {
            return .image
        }
        
        if textSticker != nil {
            return .text
        }
        
        return nil
    }
    
    init() {
        super.init(frame: .zero)
        useAutoLayout()
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 28)])
        
        addSubview(galleryView)
        NSLayoutConstraint.activate([
            galleryView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: VideoControllerConstants.trimWidth),
            galleryView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -VideoControllerConstants.trimWidth),
            galleryView.topAnchor.constraint(equalTo: topAnchor),
            galleryView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        addSubview(trimView)
        trimView.useSameSizeAsParent()
        
        galleryView.dataSource = self
        galleryView.register(VideoControllerImageStickerCell.self, forCellWithReuseIdentifier: "image")
        galleryView.register(VideoControllerTextStickerCell.self, forCellWithReuseIdentifier: "text")
        trimView.setup(galleryView: galleryView)
        
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onTrimPan(sender:))))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func resetTrim() {
        trimView.leftTrimLeadingConstraint.constant = 0
        trimView.rightTrimTrailingConstraint.constant = 0
    }
    
    func load(image: UIImage, component: OverlayComponent) {
        self.component = component
        self.imageSticker = image
        self.textSticker = nil
        (galleryView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize = CGSize(width: 28, height: 28)
        galleryView.reloadData()
        trimView.update(trimPosition: component.trimPosition)
    }
    
    func load(text: String?, component: OverlayComponent) {
        self.component = component
        self.textSticker = text
        self.imageSticker = nil
        (galleryView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize = CGSize(width: 40, height: 28)
        galleryView.reloadData()
        trimView.update(trimPosition: component.trimPosition)
    }
    
    @objc func onTrimPan(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: trimView)
        trimView.move(by: translation.x)
        sender.setTranslation(CGPoint.zero, in: trimView)
        
        layoutIfNeeded()
        customDelegate?.onAttachChanged(component: component, trimPosition: trimView.trimPosition)
    }
}

extension VideoControllerAttachView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch mode {
        case .some(.image):
            return 8
        case .some(.text):
            return 5
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch mode {
        case .some(.image):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "image", for: indexPath) as! VideoControllerImageStickerCell
            cell.imageView.image = imageSticker
            return cell
        case .some(.text):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "text", for: indexPath) as! VideoControllerTextStickerCell
            cell.labelView.text = textSticker
            return cell
        default:
            fatalError()
        }
    }
}

extension VideoControllerAttachView: VideoTrimDelegate {
    func onTrimChangedByTrimer(trimPosition: VideoTrimPosition, state: VideoTrimState, side: ControllerTrim.Side?) {
        customDelegate?.onAttachChanged(component: component, trimPosition: trimPosition)
    }
    
    func onTrimChangedByScrollInGallery(trimPosition position: VideoTrimPosition, state: VideoTrimState, currentPosition: CMTime) {
    }
}

class VideoControllerImageStickerCell: UICollectionViewCell {
    
    lazy var imageView: UIImageView = {
        let view = UIImageView().useAutoLayout()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.useSameSizeAsParent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class VideoControllerTextStickerCell: UICollectionViewCell {
    
    lazy var labelView: UILabel = {
        let view = UILabel().useAutoLayout()
        view.font = .preferredFont(forTextStyle: .footnote)
        view.textColor = .white
        view.lineBreakMode = .byTruncatingTail
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(labelView)
        labelView.useSameSizeAsParent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

