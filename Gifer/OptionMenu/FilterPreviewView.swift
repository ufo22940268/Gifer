//
//  FilterPreviewView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/19.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class FilterPreviewView: UICollectionViewCell {

    var filter: YPFilter!
    var imageView: UIImageView!
    var nameView: UILabel!
    var previewSize = CGSize(width: 56, height: 56)
    var stackView: UIStackView!
    
    var isHighlight: Bool! {
        didSet {
            var color: UIColor
            if isHighlight {
                color = tintColor
            } else {
                color = UIColor.darkGray
            }
            
            nameView.textColor = color
            if isHighlight {
                imageView.layer.borderWidth = 2
                imageView.layer.borderColor = color.cgColor
            } else {
                imageView.layer.borderWidth = 0
            }
        }
    }
    
    func setImage(_ image: UIImage, with filter: YPFilter) {
        self.filter = filter
        if let applier = filter.applier {
            var ciImage = CIImage(image: image)!
            ciImage = applier(ciImage)!
            let context = CIContext(options: nil)
            let image = UIImage(cgImage: context.createCGImage(ciImage, from: ciImage.extent)!)
            imageView.image = image
        } else {
            imageView.image = image
        }
        
        nameView.text = filter.name
        isHighlight = false
    }
    

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        contentMode = .scaleAspectFill
        clipsToBounds = true
        
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .center
        stackView.layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)])
        
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: previewSize.width),
            imageView.heightAnchor.constraint(equalToConstant: previewSize.height)])
        stackView.addArrangedSubview(imageView)
        
        nameView = UILabel()
        stackView.addArrangedSubview(nameView)
        nameView.font = UIFont.systemFont(ofSize: 12)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
