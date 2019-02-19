//
//  FiltersView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/19.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class FiltersView: UIScrollView {
    
    var imageViews: [UIImageView] = [UIImageView]()
    var stackView: UIStackView!
    
    init() {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 70)])
        
        stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: heightAnchor)
            ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        
        for filter in AllFilters {
            appendImageView(filter: filter)
        }
    }
    
    
    func appendImageView(filter: YPFilter) {
        let imageView = UIImageView()
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 54),
            imageView.heightAnchor.constraint(equalToConstant: 54),
            ])
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        stackView.addArrangedSubview(imageView)
        imageViews.append(imageView)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    func setPreviewImage(_ image: UIImage) {
        for (index, imageView) in imageViews.enumerated() {
            imageView.image = image
        }
    }
}
