//
//  StickerPanelTitles.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/8.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class StickerTitleCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var highlightBar: UIView!
    
    override var isSelected: Bool {
        didSet {
            highlightBar.isHidden = !isSelected
        }
    }
}

class StickerTitlePanel: UICollectionView {

    var titles: [UIImage]?
    
    override func awakeFromNib() {
        dataSource = self
    }

    func setTitles(titles: [UIImage]) {
        self.titles = titles
        reloadData()
    }
}

extension StickerTitlePanel: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return titles?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! StickerTitleCell
        cell.imageView.image = titles?[indexPath.row]
        return cell
    }
    
    func select(_ index: Int) {
        selectItem(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: .left)
    }
}
