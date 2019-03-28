//
//  PalettePanel.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/28.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

private class PalettePanelCell: UICollectionViewCell {
    
    var color: UIColor! {
        didSet {
            contentView.backgroundColor = color
        }
    }
}

class PalettePanel: UIView {
    
    var allColors = Palette.allColors
    
    lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0

        let collection = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout).useAutoLayout()
        collection.register(PalettePanelCell.self, forCellWithReuseIdentifier: "cell")
        collection.dataSource = self
        return collection
    }()

    init() {
        super.init(frame: CGRect.zero)
        
        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.centerXAnchor.constraint(equalTo: centerXAnchor),
            collectionView.centerYAnchor.constraint(equalTo: centerYAnchor),
            collectionView.widthAnchor.constraint(equalTo: widthAnchor),
            ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0 else {
            return
        }
        let preferredCellWidth = CGFloat(32)
        let countInRow = Int(bounds.width/preferredCellWidth)
        let cellSize = bounds.width/CGFloat(countInRow)
        let rowCount = Int(allColors.count/countInRow)
        NSLayoutConstraint.activate([
            collectionView.heightAnchor.constraint(equalToConstant: cellSize*CGFloat(rowCount))
            ])
        allColors = Array(allColors[0..<countInRow*rowCount])
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize = CGSize(width: cellSize, height: cellSize)
        collectionView.reloadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension PalettePanel: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allColors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PalettePanelCell
        cell.color = allColors[indexPath.row]
        return cell
    }
}
