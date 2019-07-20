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
    var pageVC: EditStickerPageViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let titles: [UIImage] = ["😀".image(), UIImage(named: cuppyImageNames.first!)!]
        titlePanel.setTitles(titles: titles)        
        titlePanel.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .left)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "emberPage" {
            pageVC = segue.destination as! EditStickerPageViewController
            pageVC.customDelegate = self
        }
    }
}

extension EditStickerViewController: EditStickerPageDelegate {
    func onPageTransitionTo(_ index: Int) {
        titlePanel.select(index)
    }
}
