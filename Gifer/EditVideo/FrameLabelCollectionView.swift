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
    
    weak var customDelegate: FrameLabelCollectionViewDelegate?
    
    override func awakeFromNib() {
        dataSource = self
        delegate = self
    }
    
    func dismissSelection() {
        visibleCells.forEach { deselectItem(at: self.indexPath(for: $0)!, animated: false) }
    }
}

extension FrameLabelCollectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
//        return (labels?.count ?? 0) > 1
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)!
        becomeFirstResponder()
        UIMenuController.shared.setTargetRect(cell.frame.offsetBy(dx: 0, dy: -15), in: self)
        UIMenuController.shared.setMenuVisible(true, animated: true)
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
            cell.label = labels[indexPath.row]
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
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(delete(_:))
    }
    
    override func delete(_ sender: Any?) {
        if let selectedIndex = indexPathsForSelectedItems?.first, let selectedLabel = playerItem?.labels[selectedIndex.row] {
            customDelegate?.onDeleteLabel(selectedLabel)
        }
    }
}

protocol AppendPlayerItemDelegate: class {
    func onAppendPlayerItem()
}

class FrameLabelPreviewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var label: ImagePlayerItemLabel? {
        didSet {
            guard let label = label else { return }
            loadImage(with: label.previewLoader)
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if let label = label, isSelected {
                imageView.layer.borderWidth = 2
                imageView.layer.borderColor = label.color.cgColor
            } else {
                imageView.layer.borderWidth = 0
            }
        }
    }
    
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


protocol FrameLabelCollectionViewDelegate: AppendPlayerItemDelegate {
    func onDeleteLabel(_ label: ImagePlayerItemLabel)
}
