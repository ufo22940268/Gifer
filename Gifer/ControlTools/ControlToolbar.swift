//
//  ControllToolbar.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/25.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class ControlToolbar: UICollectionView {

    var items = [ToolbarItem: ControlToolbarItemView]()
    weak var toolbarDelegate: ControlToolbarDelegate?
    
    let properties = [
        (ToolbarItem.playSpeed, (#imageLiteral(resourceName: "clock-outline.png"), "速度")),
        (ToolbarItem.crop, (#imageLiteral(resourceName: "crop-outline.png"), "剪裁")),
        (ToolbarItem.filters, (#imageLiteral(resourceName: "flash-outline.png"), "滤镜")),
        (ToolbarItem.sticker, (#imageLiteral(resourceName: "smile-wink-regular.png"), "贴纸"))
    ]
    
    override func awakeFromNib() {
        guard let superview = superview else { return  }
        backgroundColor = UIColor(named: "darkBackgroundColor")
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            ])
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: 70, height: 70)
        self.collectionViewLayout = flowLayout
        
        let gap = (bounds.width - flowLayout.itemSize.width*CGFloat(properties.count))/(CGFloat(properties.count) + 1)
        flowLayout.minimumInteritemSpacing = gap
        contentInset = UIEdgeInsets(top: 0, left: gap, bottom: 0, right: 0)
        
        dataSource = self
        delegate = self
        
        tintColor = UIColor(named: "mainColor")
        register(ControlToolbarItemView.self, forCellWithReuseIdentifier: "cell")
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

extension ControlToolbar: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let (type, _) = properties[indexPath.row]
        switch type {
        case .playSpeed:
            toolbarDelegate?.onPlaySpeedItemClicked()
        case .crop:
            toolbarDelegate?.onCropItemClicked()
        case .filters:
            toolbarDelegate?.onFiltersItemClicked()
        case .sticker:
            toolbarDelegate?.onStickerItemClicked()
        }
    }
}

protocol ControlToolbarDelegate: class {
    func onCropItemClicked()
    func onFiltersItemClicked()
    func onPlaySpeedItemClicked()
    func onStickerItemClicked()
}
