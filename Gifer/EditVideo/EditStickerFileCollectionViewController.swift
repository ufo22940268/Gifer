//
//  EditStickerFileCollectionViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/23.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import RealmSwift

fileprivate let ADD_BUTTON_ROW = 0

class EditStickerFileCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
}

class EditStickerFileCollectionViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    weak var customDelegate: EditStickerSelectionDelegate?
    var stickerFiles: Results<StickerFileModel>?

    override func viewDidLoad() {
        super.viewDidLoad()
        stickerFiles = try? Realm().objects(StickerFileModel.self).sorted(byKeyPath: "createdDate")
    }
}

extension EditStickerFileCollectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (stickerFiles?.count ?? 0) + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == ADD_BUTTON_ROW {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "add", for: indexPath)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! EditStickerFileCell
            if let data = stickerFiles![indexPath.row - 1].image {
                cell.imageView.image = UIImage(data: data)
            }
            return cell
        }
    }
}

extension EditStickerFileCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == ADD_BUTTON_ROW {
            let pickVC = UIImagePickerController()
            pickVC.allowsEditing = true
            pickVC.delegate = self
            present(pickVC, animated: true, completion: nil)
        } else {
            let file = stickerFiles![indexPath.row - 1]
            customDelegate?.onSelected(sticker: file.uiImage!)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if indexPath.row == ADD_BUTTON_ROW {
            (collectionView.cellForItem(at: indexPath)?.contentView.subviews.first! as! UIButton).isHighlighted = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if indexPath.row == ADD_BUTTON_ROW {
            (collectionView.cellForItem(at: indexPath)?.contentView.subviews.first! as! UIButton).isHighlighted = false
        }
    }
}

extension EditStickerFileCollectionViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage {
            customDelegate?.onSelected(sticker: image)
            let file = StickerFileModel()
            file.image = image.pngData()
            let realm = try! Realm()
            try? realm.write {
                realm.add(file)
            }
            collectionView.reloadData()
        }
        picker.dismiss(animated: true, completion: nil)
    }
}
