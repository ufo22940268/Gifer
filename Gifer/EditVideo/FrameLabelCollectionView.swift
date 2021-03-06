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
    
    var indexToBeSelected: IndexPath?
    
    weak var customDelegate: FrameLabelCollectionViewDelegate?
    
    override func awakeFromNib() {
        dataSource = self
        delegate = self
        UIMenuController.shared.menuItems = [UIMenuItem(title: NSLocalizedString("Clip", comment: ""), action: #selector(clip))]
    }
    
    func dismissSelection() {
        visibleCells.forEach { deselectItem(at: self.indexPath(for: $0)!, animated: false) }
    }
}

extension FrameLabelCollectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if indexPath.row == labels?.count {
            return false
        }
        
        #if DEBUG
        return true
        #else
        return (labels?.count ?? 0) > 1
        #endif
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)!
        becomeFirstResponder()
        indexToBeSelected = indexPath
        UIMenuController.shared.setTargetRect(cell.frame.offsetBy(dx: 0, dy: -17), in: self)
        UIMenuController.shared.setMenuVisible(true, animated: true)
        
        customDelegate?.onLabelSelected(labels![indexPath.row])
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
        guard let index = indexToBeSelected, let labels = labels, index.row < labels.count else { return false }
        
        if labels[index.row].videoAsset != nil {
            return [#selector(delete(_:)), #selector(clip)].contains(action)
        } else {
            return [#selector(delete(_:))].contains(action)
        }
    }
    
    override func delete(_ sender: Any?) {
        if let selectedIndex = indexPathsForSelectedItems?.first, let selectedLabel = playerItem?.labels[selectedIndex.row] {
            customDelegate?.onDeleteLabel(selectedLabel)
        }
    }
    
    @objc func clip() {
        if let label = playerItem?.labels[indexToBeSelected!.row] {
            customDelegate?.onClipLabel(label)
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
    func onLabelSelected(_ label: ImagePlayerItemLabel)
    func onClipLabel(_ label: ImagePlayerItemLabel)
}

