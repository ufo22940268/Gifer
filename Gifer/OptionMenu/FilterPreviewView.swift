//
//  FilterPreviewView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/19.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class FilterPreviewView: UIStackView {

    var filter: YPFilter!
    var imageView: UIImageView!
    var nameView: UILabel!
    
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
            let ciImage = CIImage(image: image)!
            imageView.image = UIImage(ciImage: applier(ciImage)!)
        } else {
            imageView.image = image
        }
        
        nameView.text = filter.name
        
        isHighlight = false
    }

    init() {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        
        axis = .vertical
        spacing = 4
        alignment = .center
        layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        isLayoutMarginsRelativeArrangement = true
        
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 56),
            imageView.heightAnchor.constraint(equalToConstant: 56)])
        addArrangedSubview(imageView)
        
        nameView = UILabel()
        addArrangedSubview(nameView)
        nameView.font = UIFont.systemFont(ofSize: 12)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
