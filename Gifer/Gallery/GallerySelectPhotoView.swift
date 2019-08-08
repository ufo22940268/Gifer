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

protocol GallerySelectPhotoViewDelegate: class {
    func onRemoveSelectedPhoto(withIdentifier: String)
    func onRemoveAllSelectedPhotos()
}

class GallerySelectPhotoView: UIView {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var items: [GallerySelectPhotoItem] = [GallerySelectPhotoItem]()
    weak var customDelegate: GallerySelectPhotoViewDelegate?
    
    var selectedIdentifiers: [String] {
        return items.map { $0.assetIdentifier }
    }

    override func awakeFromNib() {
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    func addItem(_ item: GallerySelectPhotoItem) {
        items.append(item)
        collectionView.insertItems(at: [IndexPath(row: max(items.count - 1, 0), section: 0)])
    }
    
    /// - Parameter sequence: Formatted index. Should be the actual index plus 1.
    func removeItem(at sequence: Int) {
        let index = sequence - 1
        items.remove(at: index)
        collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
    }
    
    func getSequence(forIdentifier identifier: String) -> Int? {
        if let offset = items.enumerated().first(where: { $0.element.assetIdentifier == identifier })?.offset {
            return offset + 1
        } else {
            return nil
        }
    }
    
    @IBAction func onDeselectAllItems(_ sender: Any) {
        items.removeAll()
        customDelegate?.onRemoveAllSelectedPhotos()
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

extension GallerySelectPhotoView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        customDelegate?.onRemoveSelectedPhoto(withIdentifier: items[indexPath.row].assetIdentifier)
        removeItem(at: indexPath.row + 1)
    }
}
