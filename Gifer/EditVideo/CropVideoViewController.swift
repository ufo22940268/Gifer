//
//  CropVideoViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/22.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

protocol CroppableViewController {
    var contentView: UIView { get }
}

class CropVideoViewController: UIViewController {

    @IBOutlet weak var imagePlayerView: ImagePlayerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func load(playerItem: ImagePlayerItem) {
        imagePlayerView.load(playerItem: playerItem)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension CropVideoViewController: CroppableViewController {
    var contentView: UIView {
        return imagePlayerView
    }
}
