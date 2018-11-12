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
    
    override func viewDidLoad() {
        let videoAsset = getTestVideo()
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestPlayerItem(forVideo: videoAsset, options: options) { (playerItem, info) in
            DispatchQueue.main.async {
                if let playerItem = playerItem {
                    //            self.player = AVPlayer(playerItem: playerItem)
                    //            self.player?.play()
                    
                    self.videoVC.load(playerItem: playerItem)
                    self.videoController.load(playerItem: playerItem)
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
