//
//  ControllToolbar.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/25.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class ControlToolbar: UIScrollView {

    var contentView: UIStackView!
    var items = [ToolbarItem: ControlToolbarItemView]()
    weak var toolbarDelegate: ControlToolbarDelegate? {
        didSet {
            for (type, item) in items {
                var selector: Selector
                switch type {
                case .playSpeed:
                    selector = #selector(toolbarDelegate?.onPlaySpeedItemClicked(sender:))
                case .crop:
                    selector = #selector(toolbarDelegate?.onCropItemClicked(sender:))
                case .filters:
                    selector = #selector(toolbarDelegate?.onFiltersItemClicked(sender:))
                }
                item.addGestureRecognizer(UITapGestureRecognizer(target: toolbarDelegate, action: selector))
            }
        }
    }
    
    override func awakeFromNib() {
        guard let superview = superview else { return  }
        backgroundColor = #colorLiteral(red: 0.0862745098, green: 0.09019607843, blue: 0.09411764706, alpha: 1)
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            ])
        setupItems()
    }
    
    private func setupItems() {
        tintColor = UIColor(named: "mainColor")
        contentView = UIStackView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.heightAnchor.constraint(equalTo: heightAnchor)
            ])
        contentView.axis = .horizontal
        contentView.spacing = 56
        contentView.alignment = .center
        contentView.isLayoutMarginsRelativeArrangement =  true
        contentView.layoutMargins = UIEdgeInsets(top: 16, left: 56, bottom: 8, right: 0)
        
        let properties = [
            (ToolbarItem.playSpeed, (#imageLiteral(resourceName: "clock-outline.png"), "速度")),
            (ToolbarItem.crop, (#imageLiteral(resourceName: "crop-outline.png"), "剪裁")),
            (ToolbarItem.filters, (#imageLiteral(resourceName: "flash-outline.png"), "滤镜"))
        ]
        for (type, property) in properties {
            let item = ControlToolbarItemView(type: type, image: property.0, title: property.1)
            contentView.addArrangedSubview(item)
            items[type] = item
            
            var selector: Selector
            switch type {
            case .playSpeed:
                selector = #selector(toolbarDelegate?.onPlaySpeedItemClicked(sender:))
            case .crop:
                selector = #selector(toolbarDelegate?.onCropItemClicked(sender:))
            case .filters:
                selector = #selector(toolbarDelegate?.onFiltersItemClicked(sender:))
            }
            item.addGestureRecognizer(UITapGestureRecognizer(target: toolbarDelegate, action: selector))
        }
    }
    
    func enableItems(_ enable: Bool) {
        for (_, item) in items {
            item.enable(enable)
        }
    }
}

@objc protocol ControlToolbarDelegate: class {
    func onCropItemClicked(sender: UIPanGestureRecognizer)
    func onFiltersItemClicked(sender: UIPanGestureRecognizer)
    func onPlaySpeedItemClicked(sender: UIPanGestureRecognizer)
}
