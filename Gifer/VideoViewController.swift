//
//  EditingViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/11/10.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit
import Photos

class VideoViewController: AVPlayerViewController {
    
    override func viewDidLoad() {
        let videoAsset = getTestVideo()
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestPlayerItem(forVideo: videoAsset, options: options) { (playerItem, info) in
//            self.player = AVPlayer(playerItem: playerItem)
//            self.player?.play()
        }
    }
}
