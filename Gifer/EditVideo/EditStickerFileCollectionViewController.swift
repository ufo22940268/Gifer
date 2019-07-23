//
//  EditStickerFileCollectionViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/23.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

fileprivate let ADD_BUTTON_ROW = 0

class EditStickerFileCollectionViewController: UIViewController {
    
    weak var customDelegate: EditStickerSelectionDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}

extension EditStickerFileCollectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == ADD_BUTTON_ROW {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "add", for: indexPath)
            return cell
        } else {
            fatalError()
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
        }
        picker.dismiss(animated: true, completion: nil)
    }
}
