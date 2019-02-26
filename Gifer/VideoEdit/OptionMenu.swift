//
//  OptionMenu.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/24.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

protocol OptionMenuDelegate: PlaySpeedViewDelegate, CropMenuViewDelegate, FiltersViewDelegate {}

class OptionMenu: UIView {
    
    weak var delegate: OptionMenuDelegate?
    var playSpeedView: PlaySpeedView!
    var playSpeedViewContainer: ControlToolbarConfirmPrompt!
    var cropMenuView: CropMenuView!
    var filtersView: FiltersView!
    
    func setPreviewImage(_ image: UIImage) {
        filtersView.setPreviewImage(image)
    }
    
    init() {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupPlaySpeedView()
        setupCropMenuView()
        setupFiltersView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func attach(menuType: ToolbarItem) {
        subviews.forEach { (subview) in
            subview.removeFromSuperview()
        }
        
        let contentView: UIView!
        switch menuType {
        case .playSpeed:
            playSpeedView.delegate = delegate
            contentView = playSpeedViewContainer
        case .crop:
            cropMenuView.delegate = delegate
            contentView = cropMenuView
        case .filters:
            filtersView.customDelegate = delegate
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
        playSpeedViewContainer = ControlToolbarConfirmPrompt(contentView: playSpeedView)
    }
    
    func setupFiltersView() {
        filtersView = FiltersView()
    }
}
