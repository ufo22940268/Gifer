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
    var fps: FPSFigure = .f5
    
    lazy var allItems: [ControlToolbarItem] = [ControlToolbarItem]()
    
    override func awakeFromNib() {
        guard let superview = superview else { return  }
        backgroundColor = UIColor(named: "darkBackgroundColor")
        
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            ])
        bounces = false
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: 70, height: 70)
        self.collectionViewLayout = flowLayout
        
        let gap = (bounds.width - flowLayout.itemSize.width*(CGFloat(displayPropertyCount) + 0.3))/(CGFloat(displayPropertyCount) + 1)
        flowLayout.minimumInteritemSpacing = gap
        showsHorizontalScrollIndicator = false
        
        dataSource = self
        delegate = self
        
        register(ControlToolbarItemView.self, forCellWithReuseIdentifier: "cell")
    }
    
    func setupAllItems(for mode: EditViewController.Mode) {
        var commonItems = ControlToolbarItem.initialAllCases
        if mode != .photo {
            commonItems.append(.fps(rate: .f5))
        }
        allItems = commonItems
        reloadData()
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
        scrollToItem(at: indexPath, at: .left, animated: true)
        let item = allItems[indexPath.row]
        switch item {
        case .playSpeed:
            toolbarDelegate?.onPlaySpeedItemClicked()
        case .crop:
            toolbarDelegate?.onCropItemClicked()
        case .font:
            toolbarDelegate?.onFontItemClicked()
        case .filters:
            toolbarDelegate?.onFiltersItemClicked()
        case .sticker:
            toolbarDelegate?.onStickerItemClicked()
        case .direction:
            reverseDirection()
            collectionView.reloadData()
            toolbarDelegate?.onDirectionItemClicked(direction: playDirection)
        case .fps:
            toolbarDelegate?.onFPSItemclicked(cell: cellForItem(at: indexPath) as! ControlToolbarItemView, currentFPS: fps)
        case .adjust:
            toolbarDelegate?.onAdjustItemClicked()
        }
    }
}

protocol ControlToolbarDelegate: class {
    func onCropItemClicked()
    func onFiltersItemClicked()
    func onFontItemClicked()
    func onPlaySpeedItemClicked()
    func onStickerItemClicked()
    func onDirectionItemClicked(direction: PlayDirection)
    func onFPSItemclicked(cell: ControlToolbarItemView, currentFPS: FPSFigure)
    func onAdjustItemClicked()
}
