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

class VideoControllerGallery: UICollectionView {

    var duration: CMTime!
    var galleryDuration: CMTime!
    
    init() {
        let flowLayout = UICollectionViewFlowLayout()
        super.init(frame: .zero, collectionViewLayout: flowLayout)
        translatesAutoresizingMaskIntoConstraints = false
        flowLayout.minimumLineSpacing = 0
        flowLayout.scrollDirection = .horizontal        
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)!
    }
    
    func setup() {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview!.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview!.trailingAnchor),
            topAnchor.constraint(equalTo: superview!.topAnchor),
            bottomAnchor.constraint(equalTo: superview!.bottomAnchor),
            heightAnchor.constraint(equalToConstant: 48),
            ])
        layer.cornerRadius = 4
        clipsToBounds = true
    }
    
    func setItemSize(_ size: CGSize) {
        (collectionViewLayout as! UICollectionViewFlowLayout).itemSize = size
    }
    
//    var itemSize: CGSize {
//        return bounds.size
//    }
//
//    func prepareImageViews(_ count: Int) {
//        arrangedSubviews.forEach { $0.removeFromSuperview() }
//
//        for index in 0..<count {
//            let imageView: UIImageView = addImageView(totalImageCount: count)
//            if index == 0 {
//                imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
//                imageView.layer.cornerRadius = 4
//            } else if index == count - 1 {
//                imageView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
//                imageView.layer.cornerRadius = 4
//            }
//        }
//    }
//
//    fileprivate func addImageView(totalImageCount: Int) -> UIImageView {
//        let imageView = UIImageView()
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        imageView.clipsToBounds = true
//        addArrangedSubview(imageView)
//        NSLayoutConstraint.activate([
//            imageView.heightAnchor.constraint(equalTo: heightAnchor)
//            ])
//        imageView.contentMode = .scaleAspectFill
//
//        return imageView
//    }
//
//    func setImage(_ image: UIImage, on index: Int) -> Void {
//        galleryImages[index].image = image
//    }
}


class VideoControllerGalleryImageCell: UICollectionViewCell {
    
    lazy var imageView: UIImageView = {
        let view = UIImageView().useAutoLayout()
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.heightAnchor.constraint(equalTo: contentView.heightAnchor),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor)
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
