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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let titles = ["😀".image()]
        titlePanel.setTitles(titles: titles)
    }
    
}
