//
//  ControllToolbar.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/25.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class ControlToolbar: UICollectionView {

    weak var toolbarDelegate: ControlToolbarDelegate?
    
    let displayPropertyCount = 4
    
    var allItems = ToolbarItem.initialAllCases
    
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
        
        let gap = (bounds.width - flowLayout.itemSize.width*(CGFloat(displayPropertyCount) + 0.3))/(CGFloat(displayPropertyCount) + 1)
        flowLayout.minimumInteritemSpacing = gap
        contentInset = UIEdgeInsets(top: 0, left: gap, bottom: 0, right: 0)
        
        dataSource = self
        delegate = self
        
        tintColor = UIColor(named: "mainColor")
        register(ControlToolbarItemView.self, forCellWithReuseIdentifier: "cell")
    }
}

extension ControlToolbar: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ControlToolbarItemView
        let item = allItems[indexPath.row]
        let (image, title) = item.viewInfo
        cell.setup(type: item, image: image, title: title)
        return cell
    }
}

extension ControlToolbar: UICollectionViewDelegate {
    
    var playDirection: PlayDirection {
        if case .direction(let playDirection) = allItems[directionIndex] {
            return playDirection
        } else {
            fatalError()
        }
    }
    
    var directionIndex: Int {
        return allItems.enumerated().filter { item in
            if case .direction = item.1 {
                return true
            } else {
                return false
            }
            }.first!.0
    }
    
    private func reverseDirection() {
        let directionIndex = allItems.enumerated().filter { item in
            if case .direction = item.1 {
                return true
            } else {
                return false
            }
            }.first!.0
        if case .direction(let playDirection) = allItems[directionIndex] {
            switch playDirection {
            case .forward:
                allItems[directionIndex] = .direction(playDirection: .backward)
            case .backward:
                allItems[directionIndex] = .direction(playDirection: .forward)
            }
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = allItems[indexPath.row]
        switch item {
        case .playSpeed:
            toolbarDelegate?.onPlaySpeedItemClicked()
        case .crop:
            toolbarDelegate?.onCropItemClicked()
        case .font:
            break;
        case .filters:
            toolbarDelegate?.onFiltersItemClicked()
        case .sticker:
            toolbarDelegate?.onStickerItemClicked()
        case .direction:
            reverseDirection()
            collectionView.reloadData()
            toolbarDelegate?.onDirectionItemClicked(direction: playDirection)
        }
    }
}

protocol ControlToolbarDelegate: class {
    func onCropItemClicked()
    func onFiltersItemClicked()
    func onPlaySpeedItemClicked()
    func onStickerItemClicked()
    func onDirectionItemClicked(direction: PlayDirection)
}
