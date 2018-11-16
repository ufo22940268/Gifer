//
//  EditViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/11/12.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit
import Photos

class EditViewController: UIViewController {
    
    var videoVC: VideoViewController!
    @IBOutlet weak var videoController: VideoController!
    
    @IBOutlet var toolbar: UIToolbar!
    override func loadView() {
        self.navigationController?.toolbar.barTintColor = #colorLiteral(red: 0.262745098, green: 0.262745098, blue: 0.262745098, alpha: 1)
        UIView.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 0.262745098, green: 0.262745098, blue: 0.262745098, alpha: 1)
        super.loadView()
    }
    
    override func viewDidLoad() {
        setToolbarItems(toolbar.items, animated: false)

        let videoAsset = getTestVideo()
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestPlayerItem(forVideo: videoAsset, options: options) { (playerItem, info) in
            DispatchQueue.main.async {
                if let playerItem = playerItem {
                    self.videoVC.load(playerItem: playerItem)
                    self.videoController.load(playerItem: playerItem)
                    self.videoController.slideDelegate = self.videoVC
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "emberVideo" {
            videoVC = segue.destination as? VideoViewController
        }
    }
}
