//
//  StickersViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/7.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

protocol EditStickerDelegate: class {
    func onAdd(sticker: StickerInfo)
    func onUpdate(sticker: StickerInfo)
}

class EditStickerViewController: UIViewController {

    @IBOutlet weak var titlePanel: StickerTitlePanel!
    
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var toolbar: UIToolbar!
    var customTransitionDelegate = EditStickerTransitionDelegate()
    @IBOutlet weak var bottomSection: UIStackView!
    @IBOutlet weak var doneBarItem: UIBarButtonItem!
    
    var pageVC: EditStickerPageViewController!
    weak var customDelegate: EditStickerDelegate?
    var stickerInfoForEdit: StickerInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
    
        let titles: [UIImage] = ["😀".image(), UIImage(named: cuppyImageNames.first!)!]
        titlePanel.setTitles(titles: titles)        
        titlePanel.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .left)
        titlePanel.customDelegate = self
        
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        previewImageView.image = stickerInfoForEdit?.image
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "emberPage" {
            pageVC = segue.destination as? EditStickerPageViewController
            pageVC.customDelegate = self
        }
    }
    
    @IBAction func onCancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onDone(_ sender: UIBarButtonItem) {
        if let image = previewImageView.image {
            if let stickerInfo = stickerInfoForEdit {
                var newInfo = stickerInfo
                newInfo.image = image
                customDelegate?.onUpdate(sticker: newInfo)
            } else {
                customDelegate?.onAdd(sticker: StickerInfo(image: image))
            }
        }
        dismiss(animated: true, completion: nil)
    }
}

extension EditStickerViewController: EditStickerPageDelegate {
    func onPageTransition(to index: Int) {
        titlePanel.select(index)
    }
    
    func onSelected(sticker: UIImage) {
        previewImageView.image = sticker
        doneBarItem.isEnabled = true
    }
}

extension EditStickerViewController: StickerTitleDelegate {
    func onTitleSelected(_ index: Int) {
        pageVC.transition(to: index)
    }
}
