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
fileprivate let REMOVE_BUTTON_SIZE = CGFloat(25)

protocol EditStickerFileCellDelegate: class {
    func onRemove(at index: Int)
}

class EditStickerFileCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    
    var index: Int!
    weak var customDelegate: EditStickerFileCellDelegate?
    var isEditable = false {
        didSet {
            removeButton.isHidden = !isEditable
            
            if isEditable {
                topConstraint.constant = REMOVE_BUTTON_SIZE/2
                leadingConstraint.constant = REMOVE_BUTTON_SIZE/2
            } else {
                topConstraint.constant = 0
                leadingConstraint.constant = 0
            }
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isEditable else { return super.hitTest(point, with: event) }
        let validBounds = bounds.applying(CGAffineTransform(scaleX: 0.5, y: 0.5))
        if validBounds.contains(point) {
            return removeButton
        } else {
            return super.hitTest(point, with: event)
        }
    }
    
    @IBAction func onRemoveTapped(_ sender: Any) {
        customDelegate?.onRemove(at: index)
    }
}

class EditStickerFileCollectionViewController: UIViewController {
    
    enum Mode {
        case normal
        case edit
        
        func getTitle() -> String {
            switch self {
            case .normal:
                return "编辑"
            case .edit:
                return "完成"
            }
        }
    }

    @IBOutlet weak var collectionView: UICollectionView!
    
    var previewFile: StickerFileModel?
    
    weak var customDelegate: EditStickerSelectionDelegate?
    var stickerFiles: Results<StickerFileModel>?
    @IBOutlet weak var editBarItem: UIBarButtonItem!
    var mode: Mode = .normal {
        didSet {
            editBarItem.title = mode.getTitle()
            collectionView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        stickerFiles = try? Realm().objects(StickerFileModel.self).sorted(byKeyPath: "createdDate")
        mode = .normal
    }
    
    @IBAction func onToggleEditButton(_ sender: Any) {
        if mode == .edit {
            mode = .normal
        } else {
            mode = .edit
        }
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
            cell.isEditable = mode == .edit
            cell.index = indexPath.row
            cell.customDelegate = self
            return cell
        }
    }
    
    func getStickerFile(byRow row: Int) -> StickerFileModel? {
        return stickerFiles?[row - 1]
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
            previewFile = file
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
            previewFile = file
            collectionView.reloadData()
        }
        picker.dismiss(animated: true, completion: nil)
    }
}

extension EditStickerFileCollectionViewController: EditStickerFileCellDelegate {
    func onRemove(at index: Int) {
        let file = getStickerFile(byRow: index)!
        
        if let previewFile = previewFile, previewFile.createdDate == file.createdDate {
            self.previewFile = nil
            customDelegate?.onSelected(sticker: nil)
        }
        
        let realm = try! Realm()
        try? realm.write {
            realm.delete(file)
        }
        
        collectionView.reloadData()
    }
}
