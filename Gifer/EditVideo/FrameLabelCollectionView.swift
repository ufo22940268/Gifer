//
//  FrameLabelCollectionView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/8/26.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class FrameLabelCollectionView: UICollectionView {

    var playerItem: ImagePlayerItem!
    var labels: [ImagePlayerItemLabel] {
        return playerItem.labels
    }
    
    override func awakeFromNib() {
        dataSource = self
    }
}

extension FrameLabelCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return labels.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row < labels.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "preview", for: indexPath) as! FrameLabelPreviewCell
            cell.loadImage(with: labels[indexPath.row].previewLoader)
            return cell
        } else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "add", for: indexPath)
        }
    }
}

class FrameLabelPreviewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    func loadImage(with loader: ImagePlayerItemLabel.PreviewLoader) {
        imageView.image = loader()
    }
}
