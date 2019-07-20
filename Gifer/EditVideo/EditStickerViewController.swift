//
//  StickersViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/7.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class EditStickerViewController: UIViewController {

    @IBOutlet weak var titlePanel: StickerTitlePanel!
    
    @IBOutlet weak var previewImageView: UIImageView!
    
    var pageVC: EditStickerPageViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let titles: [UIImage] = ["😀".image(), UIImage(named: cuppyImageNames.first!)!]
        titlePanel.setTitles(titles: titles)        
        titlePanel.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .left)
        titlePanel.customDelegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "emberPage" {
            pageVC = segue.destination as! EditStickerPageViewController
            pageVC.customDelegate = self
        }
    }
    
    @IBAction func onCancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension EditStickerViewController: EditStickerPageDelegate {
    func onPageTransition(to index: Int) {
        titlePanel.select(index)
    }
    
    func onSelected(sticker: UIImage) {
        previewImageView.image = sticker
    }
}

extension EditStickerViewController: StickerTitleDelegate {
    func onTitleSelected(_ index: Int) {
        pageVC.transition(to: index)
    }
}
