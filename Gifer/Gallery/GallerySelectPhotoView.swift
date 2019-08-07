//
//  GallerySelectPhotoView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/8/7.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

struct GallerySelectPhotoItem: Equatable {
    var assetIdentifier: String
    var image: UIImage
    
    static func ==(lhs: GallerySelectPhotoItem, rhs: GallerySelectPhotoItem) -> Bool {
        return lhs.assetIdentifier == rhs.assetIdentifier
    }
}

class GallerySelectPhotoCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
}

class GallerySelectPhotoView: UIView {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var items: [GallerySelectPhotoItem] = [GallerySelectPhotoItem]()

    override func awakeFromNib() {
        collectionView.dataSource = self
    }
    
    func addItem(_ item: GallerySelectPhotoItem) {
        items.append(item)
        collectionView.insertItems(at: [IndexPath(row: items.count - 1, section: 0)])
    }
    
    func removeItem(_ item: GallerySelectPhotoItem) {
    }
    
    func getSequence(forIdentifier identifier: String) -> Int? {
        if let offset = items.enumerated().first(where: { $0.element.assetIdentifier == identifier })?.offset {
            return offset + 1
        } else {
            return nil
        }
    }
}

extension GallerySelectPhotoView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GallerySelectPhotoCell
        cell.imageView.image = items[indexPath.row].image
        return cell
    }
}
