//
//  OptionMenu.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/24.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

protocol OptionMenuDelegate: PlaySpeedViewDelegate, FiltersViewDelegate, StickerMenuDelegate, ConfirmPromptDelegate {}

class OptionMenu: UIView {
    
    weak var delegate: OptionMenuDelegate?
    var playSpeedView: PlaySpeedView!
    var playSpeedViewContainer: ControlToolbarConfirmPrompt!
    
    var cropMenuView: CropMenuView!
    var cropMenuViewContainer: ControlToolbarConfirmPrompt!
    
    var filtersView: FiltersView!
    var filtersViewContainer: ControlToolbarConfirmPrompt!
    
    var stickerMenuView: StickerMenuView!
    var stickerMenuContainer: ControlToolbarConfirmPrompt!
    
    var activeItem: ToolbarItem?
    
    func setPreviewImage(_ image: UIImage) {
        filtersView.previewImage = image
        filtersView.reloadData()
    }
    
    init() {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(named: "darkBackgroundColor")

        setupPlaySpeedView()
        setupCropMenuView()
        setupFiltersView()
        setupStickerView()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func attach(menuType: ToolbarItem) {
        activeItem = menuType
        subviews.forEach { (subview) in
            subview.removeFromSuperview()
        }
        
        let contentView: UIView!
        switch menuType {
        case .playSpeed:
            playSpeedView.delegate = delegate
            playSpeedViewContainer.customDelegate = delegate
            contentView = playSpeedViewContainer
        case .font:
            return
        case .crop:
            return
        case .filters:
            filtersView.customDelegate = delegate
            filtersViewContainer.customDelegate = delegate
            contentView = filtersViewContainer
        case .sticker:
            stickerMenuView.customDelegate = delegate
            stickerMenuContainer.customDelegate = delegate
            contentView = stickerMenuContainer
        case .direction:
            return
        }
        
        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)])
        setNeedsDisplay()
    }
    
    func setupCropMenuView() {
        cropMenuView = CropMenuView()
        cropMenuViewContainer = ControlToolbarConfirmPrompt(contentView: cropMenuView, toolbarItem: .crop)
    }
    
    func setupPlaySpeedView() {
        playSpeedView = Bundle.main.loadNibNamed("PlaySpeedView", owner: nil, options: nil)!.first as? PlaySpeedView
        playSpeedViewContainer = ControlToolbarConfirmPrompt(contentView: playSpeedView, toolbarItem: .playSpeed)
    }
    
    func setupFiltersView() {
        filtersView = FiltersView()
        filtersViewContainer = ControlToolbarConfirmPrompt(contentView: filtersView!, toolbarItem: .filters)
    }
    
    func setupStickerView() {
        stickerMenuView = StickerMenuView()
        stickerMenuContainer = ControlToolbarConfirmPrompt(contentView: stickerMenuView, toolbarItem: .sticker)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawTopSeparator(rect: rect)
    }
}
