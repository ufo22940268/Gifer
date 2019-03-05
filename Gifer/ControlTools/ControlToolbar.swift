//
//  ControllToolbar.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/25.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class ControlToolbar: UICollectionView {

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
    
    let properties = [
        (ToolbarItem.playSpeed, (#imageLiteral(resourceName: "clock-outline.png"), "速度")),
        (ToolbarItem.crop, (#imageLiteral(resourceName: "crop-outline.png"), "剪裁")),
        (ToolbarItem.filters, (#imageLiteral(resourceName: "flash-outline.png"), "滤镜"))
    ]
    
    override func awakeFromNib() {
        guard let superview = superview else { return  }
        backgroundColor = #colorLiteral(red: 0.0862745098, green: 0.09019607843, blue: 0.09411764706, alpha: 1)
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            ])
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: 70, height: 70)
        self.collectionViewLayout = flowLayout
        
        dataSource = self
        
        tintColor = UIColor(named: "mainColor")
        register(ControlToolbarItemView.self, forCellWithReuseIdentifier: "cell")
    }
    
    private func setupItems() {
//        contentView.layoutMargins = UIEdgeInsets(top: 16, left: 56, bottom: 8, right: 0)
        
//        for (type, property) in properties {
//            let item = ControlToolbarItemView(type: type, image: property.0, title: property.1)
//            contentView.addArrangedSubview(item)
//            items[type] = item
//
//            var selector: Selector
//            switch type {
//            case .playSpeed:
//                selector = #selector(toolbarDelegate?.onPlaySpeedItemClicked(sender:))
//            case .crop:
//                selector = #selector(toolbarDelegate?.onCropItemClicked(sender:))
//            case .filters:
//                selector = #selector(toolbarDelegate?.onFiltersItemClicked(sender:))
//            }
//            item.addGestureRecognizer(UITapGestureRecognizer(target: toolbarDelegate, action: selector))
//        }
    }
    
    func enableItems(_ enable: Bool) {
        for (_, item) in items {
            item.enable(enable)
        }
    }
}

extension ControlToolbar: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return properties.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ControlToolbarItemView
        let (item, (image, title)) = properties[indexPath.row]
        cell.setup(type: item, image: image, title: title)
        return cell
    }
}

@objc protocol ControlToolbarDelegate: class {
    func onCropItemClicked(sender: UIPanGestureRecognizer)
    func onFiltersItemClicked(sender: UIPanGestureRecognizer)
    func onPlaySpeedItemClicked(sender: UIPanGestureRecognizer)
}
