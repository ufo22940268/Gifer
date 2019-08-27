//
//  FrameLabelCollectionView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/8/26.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class FrameLabelCollectionView: UICollectionView {

    var playerItem: ImagePlayerItem?
    var labels: [ImagePlayerItemLabel]? {
        return playerItem?.labels
    }
    
    weak var customDelegate: AppendPlayerItemDelegate?

    override func awakeFromNib() {
        dataSource = self
    }
}

extension FrameLabelCollectionView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let labels = labels else { return 0 }
        return labels.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let labels = labels else { fatalError() }
        if indexPath.row < labels.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "preview", for: indexPath) as! FrameLabelPreviewCell
            cell.loadImage(with: labels[indexPath.row].previewLoader)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "add", for: indexPath) as! FrameLabelAppendCell
            cell.customDelegate = customDelegate
            return cell
        }
    }
    
    func animateAfterInsertItem() {
        guard let labels = labels else { return }
        insertItems(at: [IndexPath(row: labels.count - 1, section: 0)])
    }
}

protocol AppendPlayerItemDelegate: class {
    func onAppendPlayerItem()
}

class FrameLabelPreviewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    func loadImage(with loader: ImagePlayerItemLabel.PreviewLoader) {
        imageView.image = loader()
    }
    
}

class FrameLabelAppendCell: UICollectionViewCell {
    weak var customDelegate: AppendPlayerItemDelegate?

    @IBAction func onAppendPlayerItem(_ sender: Any) {
        customDelegate?.onAppendPlayerItem()
    }
}
