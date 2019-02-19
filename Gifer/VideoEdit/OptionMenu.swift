//
//  OptionMenu.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/24.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

protocol OptionMenuDelegate: PlaySpeedViewDelegate, CropMenuViewDelegate {
    
}

class OptionMenu: UIView {
    
    enum MenuType {
        case playSpeed, crop, filters
    }
    
    weak var delegate: OptionMenuDelegate?
    var playSpeedView: PlaySpeedView!
    var cropMenuView: CropMenuView!
    var filtersView: FiltersView!
    
    func setPreviewImage(_ image: UIImage) {
        filtersView.setPreviewImage(image)
    }
    
    override func awakeFromNib() {
        setupPlaySpeedView()
        setupCropMenuView()
        setupFiltersView()
    }
    
    func attach(menuType: MenuType) {
        subviews.forEach { (subview) in
            subview.removeFromSuperview()
        }
        
        let contentView: UIView!
        switch menuType {
        case .playSpeed:
            playSpeedView.delegate = delegate
            contentView = playSpeedView
        case .crop:
            cropMenuView.delegate = delegate
            contentView = cropMenuView
        case .filters:
            contentView = filtersView
        }
        
        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)])
    }
    
    func setupCropMenuView() {
        cropMenuView = CropMenuView()
    }
    
    func setupPlaySpeedView() {
        playSpeedView = Bundle.main.loadNibNamed("PlaySpeedView", owner: nil, options: nil)!.first as! PlaySpeedView
    }
    
    func setupFiltersView() {
        filtersView = FiltersView()
    }
}
